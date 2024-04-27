import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../product/product_card.dart';

class CollectionPage extends StatefulWidget {
	final String id;
	final String title;

	const CollectionPage({super.key, required this.id, required this.title});

	@override
	State<CollectionPage> createState() => _CollectionPageState();
}

const List<Map> _sortByList = [
	{ 'key': 'COLLECTION_DEFAULT', 'name': 'Default' },
	{ 'key': 'BEST_SELLING', 'name': 'Best Selling' },
	{ 'key': 'CREATED', 'name': 'Created' },
	{ 'key': 'PRICE', 'name': 'Price' },
	{ 'key': 'TITLE', 'name': 'Title' }
];

class _CollectionPageState extends State<CollectionPage> {
	final _scaffoldKey = GlobalKey<ScaffoldState>();
	final ScrollController _listViewController = ScrollController();
	List? _products;	
	bool _sortReverse = false;
	String _sortKey = _sortByList[0]['key'];
	bool _paginationLoading = false;
	Map? _paginationInfo;
	List _availableFilters = [];
	List _activeFilters = [];
	List<bool> _filtersExpansionsState = [];
	RangeValues? _filtersPriceRange;
	double? _filtersPriceMax;

	Future<void> _getProducts({bool onInitState = false, int limit = 24, String? after}) async {
		final client = GraphQLProvider.of(context).value;

		List filters = _activeFilters.map((e) => e['input']).toList();

		final result = await client.query(
			QueryOptions(
				document: gql(r'''
					query collection(
							$id: ID
							$limit: Int
							$after: String
							$reverse: Boolean 
							$sortKey: ProductCollectionSortKeys
							$filters: [ProductFilter!]
						) 
						{
						collection (id: $id) {
							id
							handle
							products (
								first: $limit
								after: $after
								reverse: $reverse
								sortKey: $sortKey
								filters: $filters
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
								filters {
									id label type
									values { id label count input }
								}
								pageInfo {
									endCursor
									hasNextPage
								}
							}
						}
					}
				'''),
				variables: {
					'id': widget.id,
					'limit': limit,
					'after': after,
					'reverse': _sortReverse,
					'sortKey': _sortKey,
					'filters': filters,
				},
				// TODO: Fix cache and Filters
				// fetchPolicy: FetchPolicy.networkOnly
			)
		);

		if (kDebugMode) {
			print(result);
		}

		setState(() {
			if (after == null) {
				_products = result.data!['collection']['products']['edges'];
			} else {
				_products = [..._products!, ...result.data!['collection']['products']['edges']];
			}

			_availableFilters = result.data!['collection']['products']['filters'];
			_paginationLoading = false;
			_paginationInfo = result.data!['collection']['products']['pageInfo'];

			if (_filtersExpansionsState.isEmpty) {
				_filtersExpansionsState = _availableFilters.map((e) => true).toList();
			}

			for (Map filter in _availableFilters) {
				if (filter['type'] == 'PRICE_RANGE') {
					final input = jsonDecode(filter['values'][0]['input']);
					_filtersPriceRange = RangeValues(input['price']['min'].toDouble(), input['price']['max'].toDouble());
					if (onInitState) {
						_filtersPriceMax = input['price']['max'].toDouble();
					}
				}
			}
		});
	}

	bool _valueContainActiveFilter(Map value) {
		for (Map filter in _activeFilters) {
			if (filter['id'] == value['id']) {
				return true;
			}
		}
		return false;
	}

	@override
	void initState() {
		super.initState();
		WidgetsBinding.instance.addPostFrameCallback((_) async {
			_getProducts(onInitState: true);
		});
  	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			key: _scaffoldKey,
			appBar: AppBar(
				title: Text(widget.title),
				actions: [
					IconButton(
						onPressed: () async {
							await Future.delayed(const Duration(milliseconds: 200));
							if (context.mounted) {
								showModalBottomSheet<void>(
									context: context,
									builder: (BuildContext context) {
										return SafeArea(
											child: Column(
												mainAxisAlignment: MainAxisAlignment.center,
												mainAxisSize: MainAxisSize.min,
												children: <Widget>[
													Container(
														width: MediaQuery.of(context).size.width,
														padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
														decoration: BoxDecoration(
															color: Theme.of(context).primaryColor.withOpacity(.1)
														),
														child: Row(
															mainAxisAlignment: MainAxisAlignment.spaceBetween,
															children: [
																const Text('Sort by', style: TextStyle(fontSize: 18), textAlign: TextAlign.center,),
																StatefulBuilder(
																	builder: (BuildContext context, setState) => Row(
																		children: [
																			const Text('Reverse sort', style: TextStyle()),
																			const SizedBox(width: 4),
																			Switch(
																				value: _sortReverse,
																				onChanged: (bool value) {
																					setState(() {
																						_sortReverse = !_sortReverse;
																					});
																					_getProducts();
																				},
																			),
																		],
																	)
																)
															]
														),
													),
													const SizedBox(height: 12),
													for (Map item in _sortByList)
														ListTile(
															selected: item['key'] == _sortKey,
															onTap: () async {
																setState(() {
																	_sortKey = item['key'];
																});
																await Future.delayed(const Duration(milliseconds: 200));
																if (context.mounted) {
																	Navigator.pop(context);
																}
																if (_listViewController.hasClients)  {
																	_listViewController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
																}
																_getProducts();
															},
															leading: const Icon(Icons.list),
															title: Text(item['name']),
														)
												],
											),
										);
									}
								);
							}
						}, 
						icon: const Icon(Icons.sort_by_alpha)
					),
					IconButton(
						onPressed: () async {
							await Future.delayed(const Duration(milliseconds: 200));
							_scaffoldKey.currentState!.openEndDrawer();
						}, 
						icon: const Icon(Icons.filter_list)
					)
				],
			),
			endDrawer: Drawer(
				child: Column(
					children: [
						Expanded(
							child: ListView(
								padding: EdgeInsets.zero,
								children: [
									SizedBox(
										height: 120, 
										child: DrawerHeader(
											decoration: BoxDecoration(
												gradient: LinearGradient(
													colors: [Theme.of(context).primaryColor.withOpacity(.8), Theme.of(context).primaryColor],
													begin: Alignment.topCenter,
													end: Alignment.bottomCenter
												)
											),
											child: const Align(
												alignment: Alignment.bottomCenter,
												child: Padding(
													padding: EdgeInsets.only(bottom: 2 ),
													child: Text('Filter products', style: TextStyle(color: Colors.white, fontSize: 18 ) ),
												),
											),
										)
									),
									Padding(
										padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
										child: ExpansionPanelList(
											expandedHeaderPadding: EdgeInsets.zero,
											elevation: 0,
											dividerColor: Colors.grey.shade200,
											animationDuration: const Duration(milliseconds: 500),
											expansionCallback: (int index, bool isExpanded) {
												setState(() {
													_filtersExpansionsState[index] = isExpanded;
												});
											},
											children: [
												for (MapEntry filter in _availableFilters.asMap().entries)
													ExpansionPanel(
														canTapOnHeader: true,
														isExpanded: _filtersExpansionsState[filter.key],
														headerBuilder: (BuildContext context, bool isExpanded) {
															return ListTile(
																title: Text(filter.value['label']),
															);
														},
														body: Padding(
															padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
															child: Column(
																crossAxisAlignment: CrossAxisAlignment.start,
																children: [
																	if (filter.value['type'] == 'LIST')
																		 Transform.translate(
																			offset: const Offset(0, -4),
																			child: Wrap(
																				spacing: 0,
																				runSpacing: -6,
																				children: [
																					for (Map value in filter.value['values'])
																						// OutlinedButton(
																						// 	onPressed: () {

																						// 	}, 
																						// 	style: ButtonStyle(
																						// 		side:  MaterialStateProperty.all(const BorderSide(
																						// 			color: Colors.black12,
																						// 		)),
																						// 		overlayColor:  MaterialStateProperty.resolveWith<Color>((states) {
																						// 			if (states.contains(MaterialState.pressed)) {
																						// 				return Colors.black12;
																						// 			}
																						// 			return Colors.transparent;
																						// 		}),
																						// 		backgroundColor: MaterialStateProperty.all(Colors.white)
																						// 	),
																						// 	child: Text(value['label'], style: const TextStyle(color: Colors.black54),)
																						// )
																						Theme(
																							data: Theme.of(context).copyWith(
																								unselectedWidgetColor: Colors.grey.shade400,
																							),
																							child: Opacity(
																								opacity: value['count'] == 0 ? .25 : 1,
																								child: CheckboxListTile(
																									contentPadding: EdgeInsets.fromLTRB(16, 0, 11, 0),
																									dense: true,
																									controlAffinity: ListTileControlAffinity.trailing,
																									title: RichText(
																										text: TextSpan(
																											text: value['label'],
																											style: const TextStyle(color: Colors.black87),
																											children: <TextSpan>[
																												TextSpan(text: '  (${value['count']})', style: const TextStyle(color: Colors.grey, fontSize: 13)),
																											],
																										),
																									),
																									value: _valueContainActiveFilter(value),
																									onChanged: value['count'] == 0 ? null : (_) {
																										setState(() {
																											if (_valueContainActiveFilter(value)) {
																												_activeFilters.removeWhere((element) => element['id'] == value['id']);
																											} else {
																												_activeFilters.add({
																													'id': value['id'],
																													'input': jsonDecode(value['input'])
																												});
																											}
																										});

																										_getProducts();
																									},
																								),
																							)
																						)
																				],
																			)
																		)
																	else if (filter.value['type'] == 'BOOLEAN')
																		// TODO: Handle Boolean colleciton filter types
																		const Center()
																	else if (filter.value['type'] == 'PRICE_RANGE')
																		Column(
																			children: [
																				RangeSlider(
																					inactiveColor: Colors.blueGrey.shade50,
																					activeColor: Theme.of(context).primaryColor,
																					values: _filtersPriceRange!,
																					min: 0,
																					max: _filtersPriceMax!,
																					divisions: _filtersPriceMax!.toInt(),
																					labels: RangeLabels(
																						_filtersPriceRange!.start.round().toString(),
																						_filtersPriceRange!.end.round().toString(),
																					),
																					onChanged: (RangeValues values) {
																						setState(() {
																							_filtersPriceRange = values;
																						});
																					},
																					onChangeEnd: (RangeValues values) {
																						Map value = filter.value['values'][0];

																						setState(() {
																							_activeFilters.removeWhere((element) => element['id'] == value['id']);
																							_activeFilters.add({
																								'id': value['id'],
																								'input': { 'price': { 'min': _filtersPriceRange!.start, 'max': _filtersPriceRange!.end }}
																							});
																						});

																						_getProducts();
																					},
																				),
																				Transform.translate(
																					offset: const Offset(0, -4),
																						child: Padding(
																						padding: const EdgeInsets.fromLTRB(14, 0 , 14, 12),
																						child: Row(
																							mainAxisAlignment: MainAxisAlignment.spaceBetween,
																							children: [
																								const Text('\$0'),
																								Text('\$${_filtersPriceMax!}'),
																							],
																						),
																					),
																				),
																			],
																		)
																],
															),
														)
													),
											]
										),
									)
								],
							),
						),
						Container(
							padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
							child: Row(
								mainAxisAlignment: MainAxisAlignment.center,
								children: [
									ElevatedButton (
										style: ElevatedButton.styleFrom(
                			backgroundColor: Theme.of(context).primaryColor,
											foregroundColor: Colors.white
										),
										onPressed: () async {
											await Future.delayed(const Duration(milliseconds: 200));
											if (context.mounted) {
												Navigator.pop(context);
											}
										}, 
										child: const Text('Show Products')
									),
									const SizedBox(width: 10),
									if (_activeFilters.isNotEmpty)
										TextButton(
											onPressed: () async {
												await Future.delayed(const Duration(milliseconds: 200));
												setState(() {
													_activeFilters = [];
												});
												_getProducts();
											}, 
											child: Text('Clear all (${_activeFilters.length})')
										),
								],
							),
						)
					]
				)
			),
			body: _products == null 
				? const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading, please wait',))
				: _products!.isEmpty
					? Center(
						child: Column(
							mainAxisAlignment: MainAxisAlignment.center,
							children: [
								const Icon(Icons.sentiment_dissatisfied, size: 28, color: Colors.grey,),
								const SizedBox(height: 12),
								const Text('No products found!'),
								const SizedBox(height: 16),
								ElevatedButton(
									onPressed: () async {
										await Future.delayed(const Duration(milliseconds: 200));
										_scaffoldKey.currentState!.openEndDrawer();
									},
									child: const Text('Show Filters'),
								)
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