#!/usr/bin/env node

/**
 * Extract Google AI Mode Chat Sessions
 *
 * Transforms a messy Google AI Mode HTML dump into a clean conversation transcript.
 *
 * Usage:
 *   node extract.js <input.html> [output.txt]
 *
 * If output.txt is omitted, writes to <input-basename>-trimmed.txt
 */

const fs = require('fs');
const path = require('path');

// Auto-install dependencies if missing
function ensureDependencies() {
  const depsDir = path.join(__dirname, 'node_modules');
  try {
    require('cheerio');
    require('html-entities');
  } catch (e) {
    console.log('Installing dependencies (cheerio, html-entities)...');
    const { execSync } = require('child_process');
    execSync('npm install cheerio html-entities', {
      cwd: __dirname,
      stdio: 'inherit',
    });
    console.log('Dependencies installed.\n');
  }
}

ensureDependencies();

const cheerio = require('cheerio');
const { decode } = require('html-entities');

function main() {
  const args = process.argv.slice(2);

  if (args.length < 1) {
    console.error('Usage: node extract.js <input.html> [output.txt]');
    process.exit(1);
  }

  const inputFile = path.resolve(args[0]);
  const outputFile = args[1]
    ? path.resolve(args[1])
    : inputFile.replace(/\.html$/i, '') + '-trimmed.txt';

  if (!fs.existsSync(inputFile)) {
    console.error(`Error: File not found: ${inputFile}`);
    process.exit(1);
  }

  const html = fs.readFileSync(inputFile, 'utf-8');
  const $ = cheerio.load(html);

  const sections = [];

  // 1. Extract the first user query from data-mq (subsequent ones are in DOM)
  const dataMqEls = $('[data-mq]');
  if (dataMqEls.length > 0) {
    const firstMq = dataMqEls.first().attr('data-mq');
    if (firstMq && firstMq.trim()) {
      sections.push({ type: 'USER', text: firstMq.trim() });
    }
  }

  // 2. Walk the body in document order and extract conversation elements
  $('body').find('*').each(function () {
    const el = $(this);
    const classes = el.attr('class') || '';

    // User message: "You said: ..." pattern
    if (classes.includes('iMqumd')) {
      const parent = el.parent();
      const siblingText = parent.find('> span').not('.iMqumd').text().trim();
      if (siblingText) {
        sections.push({ type: 'USER', text: siblingText });
      }
      return;
    }

    // AI response heading (e.g., "Step 1: Set Up the Telegram Bot")
    if (classes.includes('otQkpb')) {
      const text = el.text().trim();
      if (text && text.length > 5) {
        sections.push({ type: 'AI', text: text });
      }
      return;
    }

    // AI response paragraph
    if (classes.includes('n6owBd') || classes.includes('awi2gc')) {
      const text = el.text().trim();
      if (text && text.length > 5) {
        sections.push({ type: 'AI', text: text });
      }
      return;
    }

    // Code blocks
    if (this.tagName === 'pre' || this.tagName === 'code') {
      const text = el.text().trim();
      if (text && text.length > 5) {
        sections.push({ type: 'CODE', text: text });
      }
      return;
    }
  });

  // 3. Extract diagrams and structured content from HTML comments
  // Google stores raw content in <!--TgQPHd||[[...]]--> JSON comments
  const commentRegex = /<!--TgQPHd\|\|(.+?)-->/g;
  let match;
  while ((match = commentRegex.exec(html)) !== null) {
    try {
      const decoded = decode(match[1]);
      const parsed = JSON.parse(decoded);

      const extractStrings = (obj) => {
        const results = [];
        if (typeof obj === 'string') {
          const isMultiLine = obj.includes('\n');
          const isLong = obj.length > 200;
          const isCodeBlock =
            obj.includes('```') ||
            obj.startsWith('    ') ||
            obj.match(/^(?:\{|\[)/);

          if (
            (isMultiLine || isLong || isCodeBlock) &&
            obj.length > 20 &&
            !obj.match(
              /^(?:true|false|null|undefined|unset|copy|edit|copied|expand|collapse)$/i,
            ) &&
            !obj.match(/^\[\d+,\d+\]$/) &&
            !obj.match(/^\d+$/) &&
            !obj.match(/^TFgppb_/) &&
            !obj.match(/^NuJjz_/) &&
            !obj.match(/^rDLshf_/) &&
            !obj.match(/^\w{8}-\w{4}-\w{4}-\w{4}-\w{12}$/) &&
            !obj.startsWith('https://') &&
            !obj.startsWith('http://') &&
            !obj.includes('/search/') &&
            !obj.includes('about-this-result') &&
            !obj.startsWith('sge_') &&
            !obj.startsWith('AF5tSO') &&
            !obj.startsWith('[') &&
            !obj.endsWith(']') &&
            !obj.match(/^Source: /)
          ) {
            results.push(obj);
          }
        } else if (Array.isArray(obj)) {
          obj.forEach((item) => results.push(...extractStrings(item)));
        } else if (typeof obj === 'object' && obj !== null) {
          Object.values(obj).forEach((val) =>
            results.push(...extractStrings(val)),
          );
        }
        return results;
      };

      const strings = extractStrings(parsed);
      strings.forEach((str) => {
        if (str.trim() && str.trim().length > 10) {
          const normalized = str.trim().replace(/\s+/g, ' ');
          const alreadyExists = sections.some(
            (s) => s.text.replace(/\s+/g, ' ') === normalized,
          );
          if (!alreadyExists) {
            sections.push({ type: 'AI', text: str.trim() });
          }
        }
      });
    } catch (e) {
      // Ignore malformed JSON in comments
    }
  }

  // 4. Post-process: remove search results, noise, and non-conversation content
  const filteredSections = sections.filter((section) => {
    const text = section.text;

    // Remove URLs and paths
    if (text.match(/^https?:\/\//)) return false;
    if (text.includes('/search/')) return false;
    if (text.includes('about-this-result')) return false;

    // Remove search result IDs and tracking
    if (text.match(/^sge_/)) return false;
    if (text.match(/^AF5tSO/)) return false;
    if (text.match(/^AF5tS0/)) return false;
    if (text.match(/^A[Ff]5tS0/)) return false;
    if (text.match(/^ErYBCnd/)) return false;
    if (text.match(/^data:image\/jpeg;base64/)) return false;
    if (text.match(/^data:image\/png;base64/)) return false;
    if (text.match(/^iVBORw0KGgo/)) return false;

    // Remove source attributions
    if (text.match(/^Source:/)) return false;

    // Remove search result titles and snippets (aggressive matching)
    const searchPatterns = [
      /^Zapier is built for enterprise-grade/,
      /^Google Sheets Integrations \| Connect/,
      /^Best Google Sheets Add-Ons/,
      /^This will open the Google Workspace/,
      /^GitHub - fmiccolis/,
      /^For example, you can set Google Sheets/,
      /^To append rows, use spreadsheets/,
      /^You can try with the CURL sample/,
      /^How to connect Claude to Google Sheets/,
      /^You can integrate your Base44 app/,
      /^Connect Google Sheets integrations/,
      /^Can I set up a Google Sheets integration/,
      /^The Google Sheets API is a RESTful/,
      /^GPT for Sheets/,
      /^Can I set up a Google Sheets integration/,
      /^The Google Sheets API is a RESTful/,
      /^GPT for Sheets/,
      /^Zapier is built for enterprise-grade/,
      /^Google Sheets Integrations \| Connect/,
      /^Best Google Sheets Add-Ons/,
      /^This will open the Google Workspace/,
      /^GitHub - fmiccolis/,
      /^Best 10 Free AI/,
      /^Public AI on Hugging Face/,
      /^mnfst\/awesome-free-llm-apis/,
      /^Managing projects in the API platform/,
      /^How to Set Billing Limits/,
      /^There is no admin API method/,
      /^How to Get 7 Free AI API Keys/,
      /^i tested every free AAPI platform/,
      /^Can I share my API key/,
      /^Generate distinct API keys/,
      /^Instead, you can create individual API keys/,
      /^Intelligent API Key Management/,
      /^This mechanism allows applications to bypass/,
      /^How to use an API/,
      /^How to Integrate the Privacy API/,
      /^Hugging Face\. Partial/,
      /^OpenAI Developer Community/,
      /^Berzaf \| AI Automation/,
      /^3\. Write a request/,
      /^Setting Spend Limits/,
      /^Configure Headless Identity API/,
      /^Lowest-Cost LLM Inference/,
      /^OpenRouter Guide/,
      /^Introduction to Azure API management/,
      /^WordPress AI Chatbots/,
      /^Web API Authentication and Authorization/,
      /^Hub Listing - Monetize/,
      /^Plan types Pay per Use/,
      /^Stripe vs PayPal/,
      /^Billplz/,
      /^best Stripe alternatives/,
      /^Regional considerations/,
      /^How to accept payments in Malaysia/,
      /^Stripe global availability/,
      /^Stripe Integration for Malaysia/,
      /^Metered billing: What it is/,
      /^Bring your own API key/,
      /^API keys don't know who's behind them/,
      /^Create your first API management service/,
      /^Yes\. OpenRouter has 20\+ free models/,
      /^For a side project or a weekend/,
      /^But here's the catch/,
      /^Once Stripe is supported/,
      /^Connect your Stripe account to BillingBee/,
      /^Built for Malaysia/,
      /^Customers buy a bundle of credits/,
      /^If you want one base subscription/,
      /^Why Pre-paid Instead of Post-paid/,
      /^Does Stripe allow flexible hybrid/,
      /^At the end of the billing cycle/,
      /^Stripe product compatibility/,
      /^Stripe Billing Review/,
      /^Implementing Pre-paid Usage Billing/,
      /^Is Stripe subscription management/,
      /^Meta replaced/,
      /^The final word/,
      /^Google Developer forums/,
      /^Telegram and WhatsApp Business API/,
      /^Google Sheets integrations \| Workflow/,
      /^WhatsApp API Pricing/,
      /^WhatsApp Business Pricing/,
      /^Telegram Review/,
      /^What Is Free on WhatsApp Business API/,
      /^TL;DR - How much does WhatsApp API cost/,
      /^WhatsApp Business Pricing Increase/,
      /^Why WhatsApp and Telegram differ/,
      /^Table_title: Current Pricing/,
      /^Qwen2\.5-VL is proficient/,
      /^Adopt mobile payments/,
      /Review.*Pricing/,
      /Pricing.*Review/,
      /Help & Support/,
      /Q&A/,
      /TL;DR/,
      /What Is Free/,
      /\| LinkedIn/,
      /\| n8n/,
      /\| Connect \.\.\./,
      / - WAWCD$/,
    ];

    for (const pattern of searchPatterns) {
      if (text.match(pattern)) return false;
    }

    return true;
  });

  // 5. Deduplicate by removing exact and near-duplicates
  const dedupedSections = [];
  const seenTexts = new Set();

  filteredSections.forEach((section) => {
    const normalized = section.text.replace(/\s+/g, ' ').trim();

    if (seenTexts.has(normalized)) return;

    const isDuplicate = dedupedSections.some((s) => {
      const existing = s.text.replace(/\s+/g, ' ').trim();
      return existing.includes(normalized) || normalized.includes(existing);
    });

    if (!isDuplicate) {
      seenTexts.add(normalized);
      dedupedSections.push(section);
    }
  });

  // 6. Build output
  const output = [];
  let lastType = null;

  dedupedSections.forEach((section) => {
    if (lastType && lastType !== section.type) {
      output.push('');
    }

    if (section.type === 'USER') {
      output.push('USER:');
      output.push(section.text);
      output.push('');
    } else if (section.type === 'CODE') {
      output.push('```');
      output.push(section.text);
      output.push('```');
      output.push('');
    } else {
      output.push(section.text);
      output.push('');
    }

    lastType = section.type;
  });

  // 7. Write output
  const finalText = output.join('\n').trim();
  fs.writeFileSync(outputFile, finalText, 'utf-8');

  console.log(`\nExtracted: ${outputFile}`);
  console.log(`  Original: ${html.length.toLocaleString()} bytes`);
  console.log(`  Trimmed:  ${finalText.length.toLocaleString()} bytes`);
  console.log(`  Reduction: ${((1 - finalText.length / html.length) * 100).toFixed(1)}%`);
  console.log(`  Sections: ${dedupedSections.length}`);
}

main();
