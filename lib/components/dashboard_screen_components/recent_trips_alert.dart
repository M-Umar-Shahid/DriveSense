import 'package:flutter/material.dart';
import '../../models/trip.dart';
import 'trip_card.dart';

class RecentTripsList extends StatelessWidget {
  final Future<List<Trip>> tripsFuture;
  const RecentTripsList({required this.tripsFuture, super.key});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Trip>>(
      future: tripsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        final trips = snap.data;
        if (trips == null || trips.isEmpty) {
          return Text("No trips found");
        }
        return Column(children: trips.map((t) => TripCard(t)).toList());
      },
    );
  }
}
