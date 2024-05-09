import 'dart:convert';

import 'package:flutter/material.dart';

class ProductRatingBadge extends StatelessWidget {
	final List metafields;
	final bool compact;

	const ProductRatingBadge({super.key, required this.metafields, required this.compact});

	@override
	Widget build(BuildContext context) {
		final rating = metafields.firstWhere((elem) => elem?['key'] == 'rating', orElse: () => null);
		final ratingCount = metafields.firstWhere((elem) => elem?['key'] == 'rating_count', orElse: () => null);

		double ratingValue = 0;
		int ratingCountValue = 0;

		if (rating != null) {
			final Map ratingAsMap = jsonDecode(rating['value']);
			ratingValue = double.parse(ratingAsMap['value']);
		}

		if (ratingCount != null) {
			ratingCountValue = int.parse(ratingCount['value']);
		}

		String reviewText = '${ratingCountValue.toString()} ${ratingCountValue == 1 ? 'review' : 'reviews'}';

		if (ratingCountValue == 0) {
			reviewText = 'No reviews';
		}

		return Column(
			children: [
				Row(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						Row(
							mainAxisAlignment: MainAxisAlignment.center,
							children: List.generate(5, (index) { 
								IconData icon = Icons.star;

								if (index + 1 - ratingValue > 0) {
									icon = Icons.star_half;
								}

								if (index + 1 > ratingValue.ceil()) {
									icon = Icons.star_border;
								}

								return Icon(
									icon,
									color: Colors.yellow.shade700,
									size: compact ? 14 : 18,
								);
							})
						),
						const SizedBox(width: 2,),
						Text(reviewText, style: TextStyle(color: Colors.grey, fontSize: compact ? 11 : 13),)
					],
				),
			],
		);
	}
}