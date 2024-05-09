import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartModel with ChangeNotifier {
	Map? _cart;

	int get count => _cart == null ? 0 : _cart!['totalQuantity'];
	Map? get cart => _cart;

	Future<void> getCart(BuildContext context) async {
		final client = GraphQLProvider.of(context).value;

		final prefs = await SharedPreferences.getInstance();
		String? cartId = prefs.getString('cart_id');

		if (kDebugMode) {
			// print(cartId);
		}

		if (cartId == null) {
			final result = await client.mutate(
				MutationOptions(
					document: gql(r'''
						mutation cartCreate {
							cartCreate {
								cart {
									id
									createdAt
								}
							}
						}
					'''),
				)
			);

			if (kDebugMode) {
				// print(result.data);
			}

			cartId = result.data!['cartCreate']['cart']['id'];
			await prefs.setString('cart_id', cartId!);
		}

		final result = await client.query(
			QueryOptions(
				document: gql(r"""
					query cart($cartId: ID!) {
						cart (id: $cartId) {
							id
							createdAt
							updatedAt
							totalQuantity
							cost {
								subtotalAmount {
									amount
									currencyCode
								}
							}
							lines (first: 50) {
								edges {
									node {
										id
										quantity
										cost {
											amountPerQuantity {
												amount,
												currencyCode
											}
										}
										merchandise {
											... on ProductVariant {
												title
												image {
													transformedSrc(maxWidth: 480, maxHeight: 480, crop: CENTER)
													altText
												}
												product {
													id
													title
													handle
												}
											}
										}
									}
								}
							}
							checkoutUrl
						}
					}
				"""),
				variables: {
					'cartId': cartId,
				}
			)
		);

		if (kDebugMode) {
			print(result);
		}

		if (result.hasException) {
			await prefs.remove('cart_id');
			if (context.mounted) {
				getCart(context);
			}
			return;
		}

		if (result.data!['cart'] == null) {
			await prefs.remove('cart_id');
			if (context.mounted) {
				getCart(context);
			}
			return;
		}

		_cart = result.data!['cart'];
		
		notifyListeners();
	}

	Future<void> cartLinesAdd(BuildContext context, List<Map> lines) async {
		final client = GraphQLProvider.of(context).value;

		final result = await client.mutate(
			MutationOptions(
				document: gql(r'''
					mutation cartLinesAdd ($cartId: ID!, $lines: [CartLineInput!]!) {
						cartLinesAdd (
							cartId: $cartId,
							lines: $lines
						)
						{
							cart {
								id
								createdAt
								updatedAt
								totalQuantity
								cost {
									subtotalAmount {
										amount
										currencyCode
									}
								}
								lines (first: 50) {
									edges {
										node {
											id
											quantity
											cost {
												amountPerQuantity {
													amount,
													currencyCode
												}
											}
											merchandise {
												... on ProductVariant {
													title
													image {
														transformedSrc(maxWidth: 480, maxHeight: 480, crop: CENTER)
														altText
													}
													product {
														id
														title
														handle
													}
												}
											}
										}
									}
								}
								checkoutUrl
							}
							userErrors {
								code
								field
								message
							}
						}
					}
				'''),
				variables: {
					'cartId': _cart!['id'],
					'lines': lines,
				},
			)
		);

		if (kDebugMode) {
			print('Line item added');
			print(result);
		}

		_cart = result.data!['cartLinesAdd']['cart'];

		notifyListeners();
	}

	Future<void> cartLinesUpdate(BuildContext context, String lineItemId, int quantity) async {
		final client = GraphQLProvider.of(context).value;

		final result = await client.mutate(
			MutationOptions(
				document: gql(r'''
					mutation cartLinesUpdate ($cartId: ID!, $lines: [CartLineUpdateInput!]!) {
						cartLinesUpdate (
							cartId: $cartId,
							lines: $lines
						) 
						{
							cart {
								id
								createdAt
								updatedAt
								totalQuantity
								cost {
									subtotalAmount {
										amount
										currencyCode
									}
								}
								lines (first: 50) {
									edges {
										node {
											id
											quantity
											cost {
												amountPerQuantity {
													amount,
													currencyCode
												}
											}
											merchandise {
												... on ProductVariant {
													title
													image {
														transformedSrc(maxWidth: 480, maxHeight: 480, crop: CENTER)
														altText
													}
													product {
														id
														title
														handle
													}
												}
											}
										}
									}
								}
								checkoutUrl
							}
							userErrors {
								code
								field
								message
							}
						} 
					}
				'''),
				variables: {
					'cartId': _cart!['id'],
					'lines': [
						{ 'id': lineItemId, 'quantity': quantity }
					],
				},
			)
		);

		if (kDebugMode) {
			print('Line item updated');
			print(result);
		}

		_cart = result.data!['cartLinesUpdate']['cart'];

		notifyListeners();

		// if (context.mounted) {
		// 	ScaffoldMessenger.of(context)
		// 		.showSnackBar(const SnackBar(content: Text('Item quantity was sucessfully updated!')));
		// }
	}

	Future<void> cartLinesRemove(BuildContext context, String lineItemId) async {		
		final client = GraphQLProvider.of(context).value;

		final result = await client.mutate(
			MutationOptions(
				document: gql(r'''
					mutation cartLinesRemove ($cartId: ID!, $lineIds: [ID!]!) {
						cartLinesRemove (
							cartId: $cartId,
							lineIds: $lineIds
						)
						{
							cart {
								id
								createdAt
								updatedAt
								totalQuantity
								cost {
									subtotalAmount {
										amount
										currencyCode
									}
								}
								lines (first: 50) {
									edges {
										node {
											id
											quantity
											cost {
												amountPerQuantity {
													amount,
													currencyCode
												}
											}
											merchandise {
												... on ProductVariant {
													title
													image {
														transformedSrc(maxWidth: 480, maxHeight: 480, crop: CENTER)
														altText
													}
													product {
														id
														title
														handle
													}
												}
											}
										}
									}
								}
								checkoutUrl
							}
							userErrors {
								code
								field
								message
							}
						}
					}
				'''),
				variables: {
					'cartId': _cart!['id'],
					'lineIds': [lineItemId],
				},
			)
		);

		if (kDebugMode) {
			print('Line item removed');
			// print(result.data);
		}

		_cart = result.data!['cartLinesRemove']['cart'];

		notifyListeners();

		// if (context.mounted) {
		// 	ScaffoldMessenger.of(context)
		// 		.showSnackBar(const SnackBar(content: Text('Item was removed from your cart!')));
		// }
	}

}