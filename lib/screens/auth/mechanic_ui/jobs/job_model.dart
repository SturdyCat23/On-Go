import 'package:flutter/material.dart';

enum JobStatus { available, accepted, completed }

class Job {
  final String client;
  final String timeAgo;
  final String urgency;
  final Color urgencyColor;
  final Color urgencyBg;
  final String issue;
  final String description;
  final String city;
  final String street;
  String? payment;
  String? date;
  int? rating;
  JobStatus status;

  Job({
    required this.client,
    required this.timeAgo,
    required this.urgency,
    required this.urgencyColor,
    required this.urgencyBg,
    required this.issue,
    required this.description,
    required this.city,
    required this.street,
    this.payment,
    this.date,
    this.rating,
    this.status = JobStatus.available,
  });
}