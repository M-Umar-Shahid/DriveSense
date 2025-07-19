import 'package:flutter/material.dart';

Widget buildManualHeatmap({
  required Map<DateTime,int> data,
  required DateTime month,
  double size = 16,
  Color baseColor = Colors.green,
}) {
  // 1. Gather all days in month
  final first = DateTime(month.year, month.month, 1);
  final last  = DateTime(month.year, month.month+1, 0);
  final daysInMonth = last.day;

  // 2. Determine the max count for scaling
  final maxCount = data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b);

  // 3. Build a list of DateTimes, padded so Su–Sa alignment
  final weekDayOfFirst = first.weekday % 7; // -> 0=Sun,1=Mon...
  final List<Widget> daySquares = [];

  // padding blanks for days before the 1st
  for (var i = 0; i < weekDayOfFirst; i++) {
    daySquares.add(Container(width: size, height: size));
  }

  // actual day squares
  for (var d = 1; d <= daysInMonth; d++) {
    final dt = DateTime(month.year, month.month, d);
    final count = data[dt] ?? 0;
    final opacity = maxCount > 0 ? (count / maxCount) : 0.0;
    daySquares.add(Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: baseColor.withOpacity(opacity.clamp(0.0, 1.0)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Text(
          '$d',
          style: TextStyle(fontSize: 10, color: Colors.black.withOpacity(0.6)),
        ),
      ),
    ));
  }

  // 4. Day‐of‐week header
  const labels = ['S','M','T','W','T','F','S'];
  final header = Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: labels
        .map((l) => SizedBox(width: size, child: Center(child: Text(l, style: const TextStyle(fontSize: 10, color: Colors.grey)))))
        .toList(),
  );

  // 5. Legend
  final legend = Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text('less', style: TextStyle(fontSize: 10)),
      const SizedBox(width: 4),
      for (var step in [0.2, 0.4, 0.6, 0.8, 1.0])
        Container(
          width: size,
          height: size,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          color: baseColor.withOpacity(step),
        ),
      const SizedBox(width: 4),
      const Text('more', style: TextStyle(fontSize: 10)),
    ],
  );

  return Column(
    children: [
      header,
      const SizedBox(height: 4),
      Wrap(spacing: 4, runSpacing: 4, children: daySquares),
      const SizedBox(height: 8),
      legend,
    ],
  );
}
