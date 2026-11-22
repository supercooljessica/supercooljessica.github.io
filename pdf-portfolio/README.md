# Jessica's PDF portfolio

An editable HTML/CSS starting point for a job application portfolio. The first
layout study contains a cover and a one-page case study for **The Fab Hoop**,
the small quadball hoop completed in December 2022.

## Files

- `index.html`: portfolio copy, project order, and page structure.
- `styles.css`: shared colors, typography, spacing, and print rules.
- `assets/`: portfolio-owned copies of images, so website changes do not break the PDF.
- `scripts/export.cjs`: PDF export with checks for missing images and page overflow.
- `output/`: generated PDF and page previews (ignored by Git).

## Preview and export

Open `index.html` in a browser to preview. For a manual PDF export, choose
US Letter, 100% scale, no margins, background graphics on, and browser headers
and footers off. The HTML contains explicit page breaks.

For the repeatable export, run these commands from this folder:

```sh
npm install
npx playwright install chromium
npm run export
```

Alternatively, set `PORTFOLIO_BROWSER` to an installed Chromium browser's
executable path. Export creates `output/jessica-portfolio-draft.pdf` and
individual PNG previews. Inspect the PDF after layout changes; the automated
checks do not replace visual review.

## Design starting point

- White, charcoal `#333333`, and the website's deep red `#a20909`.
- Roboto when locally available, then the website's Helvetica/Arial fallbacks.
  Before finalizing, we can bundle a licensed font for identical typography on
  every machine. This initial version makes no external font requests.
- US Letter portrait pages with 0.6-inch margins.
- Red project numbers, a thin red top rule, consistent captions and metadata.
- Explicit page compositions: duplicate a project section and edit its content.
  Allow extra pages for larger case studies instead of shrinking the text.

## Content status and next pass

This is a layout draft, not a complete application portfolio. Project facts and
the image come from `portfolio/selective_hoop_detection_part_1/` in the website
repository. Headlines and introductory copy are editorial proposals. The
linked external build documentation has not yet been incorporated.

Next: review the visual direction, expand the hoop case study with process
images and specific contributions, confirm any measured results, add the new
projects, and add your preferred professional name and contact information.
Do not add unverified performance numbers or imply that the small hoop has the
full-size 2024 hoop's capabilities.

The folder is not linked from the live website. It lives inside the website
repository, so committed source files may be publicly accessible if published
through GitHub Pages; keep private application material outside this repository.
