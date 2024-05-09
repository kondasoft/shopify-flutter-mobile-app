import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'product_card.dart';

class ProductRecommandations extends StatefulWidget {
	final String productId;

	const ProductRecommandations({super.key, required this.productId});

	@override
	State<ProductRecommandations> createState() => _ProductRecommandationsState();
}

class _ProductRecommandationsState extends State<ProductRecommandations> {

	@override
	Widget build(BuildContext context) {
		return Query(
			options: QueryOptions(
				document: gql(r'''
					query productRecommendations($productId: ID!) {
						productRecommendations (productId: $productId) {
							id
							title
							handle
							featuredImage {
								id
								url (transform: { maxWidth: 480, maxHeight: 480, crop: CENTER} )
								altText
							}
							images (first: 5) {
								edges {
									node {
										transformedSrc(maxWidth: 480, maxHeight: 480, crop: CENTER)
										altText
									}
								}
							}
							compareAtPriceRange {
								minVariantPrice { amount currencyCode }
								maxVariantPrice { amount currencyCode }
							}
							priceRange {
								minVariantPrice { amount currencyCode }
								maxVariantPrice { amount currencyCode }
							}
							metafields(identifiers: [
								{ namespace: "reviews" key: "rating" }
								{ namespace: "reviews" key: "rating_count" }
							]) {
								type
								namespace
								key
								value		
							}
						}
					}
				'''),
				variables: {
					'productId': widget.productId,
				},
			),
			builder: (result, {fetchMore, refetch}) {
				if (result.isLoading) {
					return const Center(
						child: CircularProgressIndicator(semanticsLabel: 'Loading, please wait',),
					);
				}

				if (kDebugMode) {
					// print(result.data!);
				}

				final List products = result.data!['productRecommendations'];

				if (products.isEmpty) {
					return const Center();
				}
				
				return Padding(
					padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
					child: Column(
						children: [
							const Text('Recommended Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),),
							const SizedBox(height: 6),
							Wrap(
								children: [
									for (dynamic product in products)
										SizedBox(
											width: MediaQuery.of(context).size.width > 600
												? MediaQuery.of(context).size.width / 3 - 6
												: MediaQuery.of(context).size.width / 2 - 8,
											height: MediaQuery.of(context).size.width > 600	
												? MediaQuery.of(context).size.width / 3 + 84
												: MediaQuery.of(context).size.width / 2 + 76,
											child: ProductCard(product: product)
										)
								],
							)
						]
					),
				);
			}
		);
	}
}


