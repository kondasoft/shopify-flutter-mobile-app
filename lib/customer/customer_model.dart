import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class CustomerModel with ChangeNotifier {
	Map? _customer;

	Map? get customer => _customer;

	Future<void> getCustomer(BuildContext context) async {
		final client = GraphQLProvider.of(context).value;
		
		final prefs = await SharedPreferences.getInstance();
		String? customerEncoded = prefs.getString('customer');

		if (customerEncoded == null) {
			_customer = null;
			notifyListeners();
			return; 
		}

		Map customer = jsonDecode(customerEncoded);

		// print(customer['expiresAt']);

		DateTime expiresAt = DateTime.parse(customer['expiresAt']);

		if (expiresAt.isAfter(DateTime.now())) {
			final result = await client.mutate(
				MutationOptions(
					document: gql(r'''
						mutation customerAccessTokenRenew ($accessToken: String!) {
							customerAccessTokenRenew(customerAccessToken: $accessToken)  {
								customerAccessToken {
									accessToken
									expiresAt
								}
								userErrors {
									field
									message
								}
							}
						}
					'''),
					variables: {
						'accessToken': customer['accessToken']
					},
				)
			);

			if (kDebugMode) {
				// print(result);
			}

			List errors = result.data!['customerAccessTokenRenew']['userErrors'];

			if (errors.isNotEmpty) {
				if (context.mounted) {
					ScaffoldMessenger.of(context).showSnackBar(SnackBar(
						content: Text('Error! Message: ${errors[0]['message']}')
					));
				}
				return;
			}

			Map accessToken = result.data!['customerAccessTokenRenew']['customerAccessToken'];

			await prefs.setString('customer', jsonEncode({
				'accessToken': accessToken['accessToken'],
				'expiresAt': accessToken['expiresAt'],
			}));

			customerEncoded = prefs.getString('customer');
			customer = jsonDecode(customerEncoded!);
		} else {
			await prefs.remove('customer');
			
			if (context.mounted) {
				ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
					content: Text('You account session has expired. Please login again to access it.')
				));
			}
			return;
		}

		final result = await client.query(
			QueryOptions(
				document: gql(r'''
					query customer ($accessToken: String!) {
						customer(customerAccessToken: $accessToken)  {
							id
							firstName
    						lastName
							email
						}
					}
				'''),
				variables: {
					'accessToken': customer['accessToken']
				},
			)
		);

		if (kDebugMode) {
			print(result);
		}

		_customer = result.data!['customer'];

		notifyListeners();
	}
}
