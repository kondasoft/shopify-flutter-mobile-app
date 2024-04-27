import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

// import 'product.dart';
import 'product_rating_stars.dart';

class ProductCard extends StatelessWidget {
	final Map product;

  	const ProductCard({super.key, required this.product});

	@override
	Widget build(BuildContext context) {
		return Card(
			margin: const EdgeInsets.all(6),
			child: Stack(
				children: <Widget>[
					Column(
						children: [
							ClipRRect(
								borderRadius: const BorderRadius.vertical(top: Radius.circular(4.0)),
								child: CachedNetworkImage(
									imageUrl: product['featuredImage']['url'] ?? '',
									placeholder: (context, url) => Container(
										color: Colors.grey.shade100,
									),
									width: MediaQuery.of(context).size.width > 600 
										? MediaQuery.of(context).size.width / 3 - 18
										: MediaQuery.of(context).size.width / 2 - 18,
									height: MediaQuery.of(context).size.width > 600 
										? MediaQuery.of(context).size.width / 3 - 18
										: MediaQuery.of(context).size.width / 2 - 18,
									fit: BoxFit.cover,
								),
							),
							Padding(
								padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
								child: Column(
									children: [
										Text(product['title'], overflow: TextOverflow.ellipsis, style: const TextStyle(), textAlign: TextAlign.center,),
										const SizedBox(height: 4),
										ProductRatingStars(
											metafields: product['metafields'],
											compact: true,
										),
										const SizedBox(height: 5),
										Row(
											mainAxisAlignment: MainAxisAlignment.center,
											children: [
												if (double.parse(product['compareAtPriceRange']['minVariantPrice']['amount']) > double.parse(product['priceRange']['minVariantPrice']['amount']))
													Padding(
														padding: const EdgeInsets.only(right: 5),
														child: Opacity(
															opacity: .5,
															child: Text('\$${product['compareAtPriceRange']['minVariantPrice']['amount']}'.replaceAll('.0', ''), style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500, decoration: TextDecoration.lineThrough)),
														),
													),
												Text('\$${product['priceRange']['minVariantPrice']['amount']}'.replaceAll('.0', ''), style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500))
											],
										)
										
									],
								),
							),
						],
					),
					Positioned.fill(
						child: Material(
							color: Colors.transparent,
							child: InkWell(
								onTap: () async {
									await Future.delayed(const Duration(milliseconds: 200));

									if (context.mounted) {
										// Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProductPage(
										// 	id: product['id'],
										// 	title: product['title'],
										// )));
									}
								}
							)
						)
					)
				]
			),
		);
	}
}