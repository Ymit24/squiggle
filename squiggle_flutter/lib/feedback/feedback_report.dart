/// Limits enforced by the report server, mirrored so the dialog can stop
/// input at the same point.
const maxFeedbackTitleLength = 120;
const maxFeedbackDescriptionLength = 4000;

class FeedbackReport {
  const FeedbackReport({
    required this.kind,
    required this.title,
    required this.description,
  });

  final FeedbackKind kind;
  final String title;
  final String description;
}

enum FeedbackKind { bug, feature }

/// The GitHub issue a report became.
class SubmittedReport {
  const SubmittedReport({required this.number, required this.url});

  final int number;
  final Uri url;
}
