/// Canonical on-disk location of Johnny Pain's Greyskull LP program text.
///
/// See [officialBookPdfRepoPath] and [docs/reference/README.md](https://github.com/suncoast-servers/GreyskullLP/blob/main/docs/reference/README.md).
library;

/// Repo-relative path from project root (for docs and tooling).
const String officialBookPdfRepoPath =
    'docs/reference/Greyskull_LP_3rd_edition.pdf';

/// Human-readable edition label for UI and release notes.
const String officialProgramEditionLabel = 'Greyskull LP (3rd edition)';

// TODO(program-fidelity): When Johnny Pain publishes the 4th edition, add
// docs/reference/Greyskull_LP_4th_edition.pdf (or successor filename), update
// barbell/calisthenics templates per owner approval, and bump
// [officialProgramEditionLabel]. Until then, implement against 3rd edition only.
