import 'dart:convert' show jsonDecode;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:url_launcher/url_launcher.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CustomerOrders extends StatefulWidget {
	const CustomerOrders({super.key});

	@override
	State<CustomerOrders> createState() => _CustomerOrdersState();
}

class _CustomerOrdersState extends State<CustomerOrders> {
	final _scaffoldKey = GlobalKey<ScaffoldState>();
	final ScrollController _listViewController = ScrollController();
	List? _orders;
	bool _paginationLoading = false;
	Map? _paginationInfo;

	Future<void> _getOrders({int limit = 24, String? after}) async {
		final client = GraphQLProvider.of(context).value;

		final prefs = await SharedPreferences.getInstance();
		String? customerEncoded = prefs.getString('customer');

		if (customerEncoded == null) {
			return;
		}

		Map customer = jsonDecode(customerEncoded);
		String accessToken = customer['accessToken'];

		final result = await client.query(
			QueryOptions(
				document: gql(r'''
					query customer($accessToken: String! $limit: Int $after: String) {
						customer (customerAccessToken: $accessToken) {
							orders (first: $limit after: $after) {
								edges { 
									node {
										id
										name
										processedAt
										totalPrice {
											amount
											currencyCode
										}
										financialStatus
										fulfillmentStatus
										customerUrl
									}
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
					'accessToken': accessToken,
					'limit': limit,
					'after': after,
				}
			)
		);

		if (kDebugMode) {
			print(result);
		}

		setState(() {
			if (after == null) {
				_orders = result.data!['customer']['orders']['edges'];
			} else {
				_orders = [..._orders!, ...result.data!['customer']['orders']['edges']];
			}

			_paginationLoading = false;
			_paginationInfo = result.data!['customer']['orders']['pageInfo'];
		});
	}

	@override
	void initState() {
		super.initState();
		WidgetsBinding.instance.addPostFrameCallback((_) async {
			_getOrders();
		});
  }

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			key: _scaffoldKey,
			appBar: AppBar(
				title: const Text('Orders'),
			),
			body: _orders == null 
				? const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading, please wait',))
				: _orders!.isEmpty
					? Center(
						child: Column(
							mainAxisAlignment: MainAxisAlignment.center,
							children: [
								const Icon(Icons.sentiment_dissatisfied, size: 28, color: Colors.grey,),
								const SizedBox(height: 12),
								const Text('No orders found!'),
								const SizedBox(height: 16),
								ElevatedButton(
									onPressed: () async {
										await Future.delayed(const Duration(milliseconds: 200));
										if (context.mounted) {
											Navigator.of(context).pop();
										}
									},
									child: const Text('Continue Shopping'),
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
									_getOrders(after: _paginationInfo!['endCursor']);
								}
							}
							return false;
						},
						child: Column(
							children: [
								Expanded(
									child: ListView(
										controller: _listViewController,
										padding: const EdgeInsets.fromLTRB(6, 8, 6, 48),
										children: [
											for (dynamic edge in _orders!)
												Card(
													margin: const EdgeInsets.all(6),
													child: Padding(
														padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
														child: Row(
															mainAxisAlignment: MainAxisAlignment.spaceBetween,
															children: [
																Column(
																	crossAxisAlignment: CrossAxisAlignment.start,
																	children: [
																		Container(
																			padding: const EdgeInsets.only(bottom: 4),
																			decoration: const BoxDecoration(
																				border: Border(
																					bottom: BorderSide(width: 1, color: Colors.black54)
																				)
																			),
																			child: Text('Order ${edge['node']['name']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),)
																		),
																		const SizedBox(height: 8),
																		Row(
																			children: [
																				const Text('Date:', style: TextStyle(color: Colors.grey),),
																				const SizedBox(width: 4),
																				Text(DateFormat.yMMMMd().format(DateTime.parse(edge['node']['processedAt']))),
																			],
																		),
																		const SizedBox(height: 4,),
																		Row(
																			children: [
																				const Text('Payment status:', style: TextStyle(color: Colors.grey),),
																				const SizedBox(width: 4),
																				Text(edge['node']['financialStatus']),
																			],
																		),
																		const SizedBox(height: 4,),
																		Row(
																			children: [
																				const Text('Fulfillment status:', style: TextStyle(color: Colors.grey),),
																				const SizedBox(width: 4),
																				Text(edge['node']['fulfillmentStatus']),
																			],
																		),
																		const SizedBox(height: 4,),
																		Row(
																			children: [
																				const Text('Total:', style: TextStyle(color: Colors.grey),),
																				const SizedBox(width: 4),
																				Text('\$${edge['node']['totalPrice']['amount']} ${edge['node']['totalPrice']['currencyCode']}'),
																			],
																		),
																	],
																),
																const SizedBox(width: 12,),
																ElevatedButton(
																	onPressed: () async {
																		await Future.delayed(const Duration(milliseconds: 200));
																		launchUrl(Uri.parse(edge['node']['customerUrl']));
																	},
																	child: const Text('Details'),
																),
															],
														),
													)
												)
										],
									)
								),
								if (_paginationLoading)
									const LinearProgressIndicator(semanticsLabel: 'Loading',)
							]
						)
					),
		);
	}
}