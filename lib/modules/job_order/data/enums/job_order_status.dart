enum JobOrderStatus {
  none(0),
  forReview(1),
  accepted(2),
  inTransit(3),
  inProgress(4),
  completed(5),
  cancelled(6);

  const JobOrderStatus(this.value);
  final int value;
}
