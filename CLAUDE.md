# MathML Core Testsuite (mmlcore-testsuite)

Local mirror of WPT MathML Core tests synced from `https://github.com/web-platform-tests/wpt/tree/master/mathml`.

## Quick facts

- **Source**: WPT monorepo `mathml/` (git submodule)
- **Spec**: https://w3c.github.io/mathml-core/
- **Sync**: `scripts/sync.rb` — clones/pulls wpt, extracts `<math>` elements to `mathml/*.mml`
- **Format**: WPT reftest + testharness.js

## Sync

```bash
bundle install
./scripts/sync.rb
```

Uses sparse checkout to clone only the `mathml/` directory from the wpt monorepo (shallow, not full ~20 GB). Extracts `<math>` elements from HTML/XHTML files into standalone `.mml` files in `mathml/`, preserving directory structure. Raw WPT files remain in `.wpt-cache/mathml/`.
