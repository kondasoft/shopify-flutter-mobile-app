import 'dart:convert' show jsonDecode;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'customer_address_add.dart';
import 'customer_address_edit.dart';

class CustomerAddresses extends StatefulWidget {
	const CustomerAddresses({super.key});

	@override
	State<CustomerAddresses> createState() => _CustomerAddressesState();
}

class _CustomerAddressesState extends State<CustomerAddresses> {
	final _scaffoldKey = GlobalKey<ScaffoldState>();
	final ScrollController _listViewController = ScrollController();
	String? _defaultAddressId;
	List? _addresses;
	bool _paginationLoading = false;
	Map? _paginationInfo;

	Future<void> _getAddresses({int limit = 24, String? after}) async {
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
							defaultAddress {
								id
							}
							addresses (first: $limit after: $after) {
								edges { 
									node {
										id
										address1
										address2
										city
										company
										country
										countryCodeV2
										firstName
										formatted
										formattedArea
										lastName
										latitude
										longitude
										name
										phone
										province
										provinceCode
										zip
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
				_addresses = result.data!['customer']['addresses']['edges'];
			} else {
				_addresses = [..._addresses!, ...result.data!['customer']['addresses']['edges']];
			}

			if (result.data!['customer']['defaultAddress'] != null) {
				_defaultAddressId = result.data!['customer']['defaultAddress']['id'];
			}

			_paginationLoading = false;
			_paginationInfo = result.data!['customer']['addresses']['pageInfo'];
		});
	}

	Future<void> _deleteAddress(String id) async {
		final client = GraphQLProvider.of(context).value;

		final prefs = await SharedPreferences.getInstance();
		String? customerEncoded = prefs.getString('customer');

		if (customerEncoded == null) {
			return;
		}

		Map customer = jsonDecode(customerEncoded);
		String accessToken = customer['accessToken'];

		final result = await client.mutate(
			MutationOptions(
				document: gql(r'''
					mutation customerAddressDelete($accessToken: String! $id: ID!) {
						customerAddressDelete (customerAccessToken: $accessToken id: $id) {

						}
					}
				'''),
				variables: {
					'accessToken': accessToken,
					'id': id
				}
			)
		);

		if (kDebugMode) {
			print(result);
		}

		if (context.mounted) {
			ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
				content: Text('Address was successfully deleted!')
			));
		}

		_getAddresses();
	}

	Future<void> _setDefaultAddress(String addressId) async {
		final client = GraphQLProvider.of(context).value;

		final prefs = await SharedPreferences.getInstance();
		String? customerEncoded = prefs.getString('customer');

		if (customerEncoded == null) {
			return;
		}

		Map customer = jsonDecode(customerEncoded);
		String accessToken = customer['accessToken'];

		final result = await client.mutate(
			MutationOptions(
				document: gql(r'''
					mutation customerDefaultAddressUpdate($accessToken: String! $addressId: ID!) {
						customerDefaultAddressUpdate (customerAccessToken: $accessToken addressId: $addressId) {
							customerUserErrors {
								code
								field
								message
							}
						}
					}
				'''),
				variables: {
					'accessToken': accessToken,
					'addressId': addressId,
				}
			)
		);

		if (kDebugMode) {
			print(result);
		}

		if (context.mounted) {
			if (result.hasException) {
				ScaffoldMessenger.of(context).showSnackBar(SnackBar(
					content: Text('Error! Message: ${result.exception!.graphqlErrors[0].message}')
				));
			} else {
				List errors = result.data!['customerDefaultAddressUpdate']['customerUserErrors'];

				if (errors.isEmpty) {
					ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
						content: Text('Address was successfully set as default')
					));
				} else {
					ScaffoldMessenger.of(context).showSnackBar(SnackBar(
						content: Text('Error! Message: ${errors[0]['message']}')
					));
				}
			}
		}

		_getAddresses();
	}

	@override
	void initState() {
		super.initState();
		WidgetsBinding.instance.addPostFrameCallback((_) async {
			_getAddresses();
		});
  	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			key: _scaffoldKey,
			appBar: AppBar(
				title: const Text('Addresses'),
				actions: [
					IconButton(
						onPressed: () async {
							await Future.delayed(const Duration(milliseconds: 200));
							if (context.mounted) {
								await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CustomerAddressAdd()));
								_getAddresses();
							}
						},
						icon: const Icon(Icons.add, semanticLabel: 'New Address'),
						iconSize: 28,
					)
				],
			),
			body: _addresses == null 
				? const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading, please wait',))
				: _addresses!.isEmpty
					? Center(
						child: Column(
							mainAxisAlignment: MainAxisAlignment.center,
							children: [
								const Icon(Icons.sentiment_dissatisfied, size: 28, color: Colors.grey,),
								const SizedBox(height: 12),
								const Text('No addresses yet!'),
								const SizedBox(height: 16),
								ElevatedButton(
									onPressed: () async {
										await Future.delayed(const Duration(milliseconds: 200));
										if (context.mounted) {
											await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CustomerAddressAdd()));
											_getAddresses();
										}
									},
									child: const Text('Add a new address'),
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
									_getAddresses(after: _paginationInfo!['endCursor']);
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
											for (dynamic edge in _addresses!)
												Card(
													color: edge['node']['id'] == _defaultAddressId ? Colors.blueGrey.shade50 : null,
													margin: const EdgeInsets.all(6),
													child: Padding(
														padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
														child: Row(
															mainAxisAlignment: MainAxisAlignment.spaceBetween,
															children: [
																Flexible(
																	child: Column(
																		crossAxisAlignment: CrossAxisAlignment.start,
																		children: [
																			Container(
																				padding: const EdgeInsets.only(bottom: 4),
																				decoration: const BoxDecoration(
																					border: Border(
																						bottom: BorderSide(width: 1, color: Colors.black54)
																					)
																				),
																				child: Text(
																					edge['node']['id'] == _defaultAddressId ? 'Default Address' : 'Address', 
																					style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
																				),
																			),
																			const SizedBox(height: 8),
																			Text(edge['node']['name']),
																			Text(edge['node']['formatted'].join(', ')),
																			const SizedBox(height: 8,),
																			Row(
																				children: [
																					OutlinedButton(
																						onPressed: () async {
																							await Future.delayed(const Duration(milliseconds: 200));
																							if (context.mounted) {
																								await Navigator.of(context).push(MaterialPageRoute(builder: (context) => CustomerAddressEdit(
																									address: edge['node'],
																								)));
																								_getAddresses();
																							}
																						},
																						child: const Text('Edit address')
																					),
																					const SizedBox(width: 8),
																					if (edge['node']['id'] != _defaultAddressId)
																						OutlinedButton(
																							onPressed: () {
																								_setDefaultAddress(edge['node']['id']);
																							}, 
																							child: const Text('Set as default')
																						),
																				],
																			)
																		]
																	),
																),
																const SizedBox(width: 12,),
																IconButton(
																	onPressed: () async {
																		await Future.delayed(const Duration(milliseconds: 200));
																		_deleteAddress(edge['node']['id']);
																	},
																	icon: const Icon(Icons.delete, semanticLabel: 'Delete address',),
																	color: Colors.red.shade700,
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