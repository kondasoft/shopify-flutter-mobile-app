import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'product/product_card.dart';

class SearchPage extends StatefulWidget {
	const SearchPage({super.key});

	@override
	State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
	final _scaffoldKey = GlobalKey<ScaffoldState>();
	final ScrollController _listViewController = ScrollController();
	final TextEditingController _textController = TextEditingController();
	String? _query;
	List? _products;
	bool _paginationLoading = false;
	Map? _paginationInfo;

	Future<void> _getProducts({int limit = 12, String? after}) async {
		final client = GraphQLProvider.of(context).value;

		final result = await client.query(
			QueryOptions(
				document: gql(r"""
					query products($limit: Int $after: String $query: String) {
						products (
							first: $limit
							after: $after
							query: $query
						) 
						{
							edges { 
								node {
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
							pageInfo {
								endCursor
								hasNextPage
							}
						}
					}
				"""),
				variables: {
					'limit': limit,
					'after': after,
					'query': _query
				},
			)
		);

		if (kDebugMode) {
			print(result);
		}

		setState(() {
			if (after == null) {
				_products = result.data!['products']['edges'];
			} else {
				_products = [..._products!, ...result.data!['products']['edges']];
			}

			_paginationLoading = false;
			_paginationInfo = result.data!['products']['pageInfo'];
		});
	}

	@override
	void initState() {
		super.initState();
  	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			key: _scaffoldKey,
			appBar: AppBar(
				title: Container(
					width: double.infinity,
					height: 40,
					decoration: BoxDecoration(
						color: Colors.white, 
						borderRadius: BorderRadius.circular(4)
					),
					child: Center(
						child: TextField(
							controller: _textController,
							autofocus: true,
							decoration: InputDecoration(
								prefixIcon: const Icon(Icons.search, size: 22, color: Colors.grey,),
								suffixIcon: IconButton(
									icon: const Icon(Icons.clear),
									color: _textController.text.isEmpty ? Colors.grey : null,
									iconSize: 22,
									onPressed: () {
										_textController.clear();
										setState(() {
											_query = null;
											_products = null;
										});
									},
								),
								hintText: 'Search for...',
								border: InputBorder.none
							),
							onChanged: (value) {
								setState(() {
									_query = value;
								});
								if (value.isEmpty) {
									setState(() {
										_products = null;
									});
								} else {
									_getProducts();
								}
							},
						),
					),
				),
			),
			body: _products == null 
				? const Center()
				: _products!.isEmpty
					? Center(
						child: Column(
							mainAxisAlignment: MainAxisAlignment.center,
							children: const [
								Icon(Icons.sentiment_dissatisfied, size: 28, color: Colors.grey,),
								SizedBox(height: 12),
								Text('No products found!'),
								SizedBox(height: 16),
							],
						)
					)
					: NotificationListener<ScrollEndNotification>(
						onNotification: (scrollEnd) {
							if (scrollEnd.metrics.atEdge) {
								bool isTop = scrollEnd.metrics.pixels == 0;
								
								if (isTop) { return false; }

								if (_paginationInfo != null && _paginationInfo!['hasNextPage']) {
									setState(() {
										_paginationLoading = true;
									});
									_getProducts(after: _paginationInfo!['endCursor']);
								}
							}
							return false;
						},
						child: Column(
							children: [
								Expanded(
									child: GridView.count(
										controller: _listViewController,
										crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
										childAspectRatio: MediaQuery.of(context).size.width > 600 ? .75 : .71,
										padding: const EdgeInsets.fromLTRB(6, 8, 6, 48),
										children: [
											for (dynamic edge in _products!)
												ProductCard(product: edge['node'])
										],
									)
								),
								if (_paginationLoading)
									const LinearProgressIndicator(semanticsLabel: 'Loading',)
							]
						)
			)
		);
	}
}