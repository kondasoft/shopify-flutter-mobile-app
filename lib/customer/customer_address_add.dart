import 'dart:convert' show jsonDecode;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

final List<String> addressFields = [
	'First name', 'Last name', 'Company', 'Address 1', 'Address 2', 'City', 'Country', 'Province', 'Postal/Zip code', 'Phone'
];

final List<String> countries = [
	'Afghanistan',
	'Åland Islands',
	'Albania',
	'Algeria',
	'Andorra',
	'Angola',
	'Anguilla',
	'Antigua and Barbuda',
	'Argentina',
	'Armenia',
	'Aruba',
	'Ascension Island',
	'Australia',
	'Austria',
	'Azerbaijan',
	'Bahamas',
	'Bahrain',
	'Bangladesh',
	'Barbados',
	'Belarus',
	'Belgium',
	'Belize',
	'Benin',
	'Bermuda',
	'Bhutan',
	'Bolivia',
	'Bosnia and Herzegovina',
	'Botswana',
	'Brazil',
	'British Indian Ocean Territory',
	'British Virgin Islands',
	'Brunei',
	'Bulgaria',
	'Burkina Faso',
	'Burundi',
	'Cambodia',
	'Cameroon',
	'Canada',
	'Cape Verde',
	'Caribbean Netherlands',
	'Cayman Islands',
	'Central African Republic',
	'Chad',
	'Chile',
	'China',
	'Christmas Island',
	'Cocos (Keeling) Islands',
	'Colombia',
	'Comoros',
	'Congo - Brazzaville',
	'Congo - Kinshasa',
	'Cook Islands',
	'Costa Rica',
	'Croatia',
	'Curaçao',
	'Cyprus',
	'Czechia',
	'Côte d"Ivoire',
	'Denmark',
	'Djibouti',
	'Dominica',
	'Dominican Republic',
	'Ecuador',
	'Egypt',
	'El Salvador',
	'Equatorial Guinea',
	'Eritrea',
	'Estonia',
	'Eswatini',
	'Ethiopia',
	'Falkland Islands',
	'Faroe Islands',
	'Fiji',
	'Finland',
	'France',
	'French Guiana',
	'French Polynesia',
	'French Southern Territories',
	'Gabon',
	'Gambia',
	'Georgia',
	'Germany',
	'Ghana',
	'Gibraltar',
	'Greece',
	'Greenland',
	'Grenada',
	'Guadeloupe',
	'Guatemala',
	'Guernsey',
	'Guinea',
	'Guinea-Bissau',
	'Guyana',
	'Haiti',
	'Honduras',
	'Hong Kong SAR',
	'Hungary',
	'Iceland',
	'India',
	'Indonesia',
	'Iraq',
	'Ireland',
	'Isle of Man',
	'Israel',
	'Italy',
	'Jamaica',
	'Japan',
	'Jersey',
	'Jordan',
	'Kazakhstan',
	'Kenya',
	'Kiribati',
	'Kosovo',
	'Kuwait',
	'Kyrgyzstan',
	'Laos',
	'Latvia',
	'Lebanon',
	'Lesotho',
	'Liberia',
	'Libya',
	'Liechtenstein',
	'Lithuania',
	'Luxembourg',
	'Macao SAR',
	'Madagascar',
	'Malawi',
	'Malaysia',
	'Maldives',
	'Mali',
	'Malta',
	'Martinique',
	'Mauritania',
	'Mauritius',
	'Mayotte',
	'Mexico',
	'Moldova',
	'Monaco',
	'Mongolia',
	'Montenegro',
	'Montserrat',
	'Morocco',
	'Mozambique',
	'Myanmar (Burma)',
	'Namibia',
	'Nauru',
	'Nepal',
	'Netherlands',
	'New Caledonia',
	'New Zealand',
	'Nicaragua',
	'Niger',
	'Nigeria',
	'Niue',
	'Norfolk Island',
	'North Macedonia',
	'Norway',
	'Oman',
	'Pakistan',
	'Palestinian Territories',
	'Panama',
	'Papua New Guinea',
	'Paraguay',
	'Peru',
	'Philippines',
	'Pitcairn Islands',
	'Poland',
	'Portugal',
	'Qatar',
	'Réunion',
	'Romania',
	'Russia',
	'Rwanda',
	'Samoa',
	'San Marino',
	'São Tomé and Príncipe',
	'Saudi Arabia',
	'Senegal',
	'Serbia',
	'Seychelles',
	'Sierra Leone',
	'Singapore',
	'Sint Maarten',
	'Slovakia',
	'Slovenia',
	'Solomon Islands',
	'Somalia',
	'South Africa',
	'South Georgia and South Sandwich Islands',
	'South Korea',
	'South Sudan',
	'Spain',
	'Sri Lanka',
	'St. Barthélemy',
	'St. Helena',
	'St. Kitts and Nevis',
	'St. Lucia',
	'St. Martin',
	'St. Pierre and Miquelon',
	'St. Vincent and Grenadines',
	'Sudan',
	'Suriname',
	'Svalbard and Jan Mayen',
	'Sweden',
	'Switzerland',
	'Taiwan',
	'Tajikistan',
	'Tanzania',
	'Thailand',
	'Timor-Leste',
	'Togo',
	'Tokelau',
	'Tonga',
	'Trinidad and Tobago',
	'Tristan da Cunha',
	'Tunisia',
	'Turkey',
	'Turkmenistan',
	'Turks and Caicos Islands',
	'Tuvalu',
	'U.S. Outlying Islands',
	'Uganda',
	'Ukraine',
	'United Arab Emirates',
	'United Kingdom',
	'United States',
	'Uruguay',
	'Uzbekistan',
	'Vanuatu',
	'Vatican City',
	'Venezuela',
	'Vietnam',
	'Wallis and Futuna',
	'Western Sahara',
	'Yemen',
	'Zambia',
	'Zimbabwe',
];

class CustomerAddressAdd extends StatefulWidget {
	const CustomerAddressAdd({super.key});

	@override
	State<CustomerAddressAdd> createState() => _CustomerAddressAddState();
}

class _CustomerAddressAddState extends State<CustomerAddressAdd> {
	final _formKey = GlobalKey<FormState>();
	bool _loading = false;
	final Map _addressSavedFields = {};

	Future<void> _addNewAddress() async {
		setState((){
			_loading = true;
		});

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
					mutation customerAddressCreate($accessToken: String! $address: MailingAddressInput!) {
						customerAddressCreate (customerAccessToken: $accessToken address: $address) {
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
					'address': {
						'firstName': _addressSavedFields['First name'],
						'lastName': _addressSavedFields['Last name'],
						'company': _addressSavedFields['Company'],
						'address1': _addressSavedFields['Address 1'],
						'address2': _addressSavedFields['Address 2'],
						'city': _addressSavedFields['City'],
						'country': _addressSavedFields['Country'],
						'province': _addressSavedFields['Province'],
						'zip': _addressSavedFields['Postal/Zip code'],
						'phone': _addressSavedFields['Phone'],
					}
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
				List errors = result.data!['customerAddressCreate']['customerUserErrors'];

				if (errors.isEmpty) {
					ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
						content: Text('Address was successfully created! Pleas wait...')
					));

					await Future.delayed(const Duration(seconds: 3));

					if (context.mounted) {
						Navigator.of(context).pop();
					}
					
				} else {
					ScaffoldMessenger.of(context).showSnackBar(SnackBar(
						content: Text('Error! Message: ${errors[0]['message']}')
					));
				}
			}
		}

		setState(() {
			_loading = false;
		});
	}

	Widget _buildAddressField(String field) {
		if (field == 'Country') {
			return Column(
				children: [
					Autocomplete<String>(
						optionsBuilder: (TextEditingValue textEditingValue) {
							debugPrint(textEditingValue.text.toLowerCase());
							
							if (textEditingValue.text == '') {
								return const Iterable<String>.empty();
							}
							return countries.where((String country) {
								return country.toLowerCase().contains(textEditingValue.text.toLowerCase());
							});
						},
						fieldViewBuilder: ((context, textEditingController, focusNode, onFieldSubmitted) {
							return TextFormField(
								controller: textEditingController,
								focusNode: focusNode,
								onEditingComplete: onFieldSubmitted,
								decoration: const InputDecoration(
									border: OutlineInputBorder(),
									hintText: 'Country'
								),
								validator: (value) {
									if (value == null || value.isEmpty) {
										return 'Please enter your $field';
									}
									return null;
								},
								onSaved: (value) {
									setState(() {
										_addressSavedFields[field] = value;
									});
								},
							);
						}),
						onSelected: (String value) {
							setState(() {
								_addressSavedFields[field] = value;
							});
						}
					),
					const SizedBox(height: 12),
				],
			);
		} else {
			return Column(
				children: [
					TextFormField(
						autofocus: field == 'First name',
						decoration: InputDecoration(
							border: const OutlineInputBorder(), 
							labelText: field,
						),
						validator: (value) {
							if (field == 'Company' || field  == 'Phone' || field == 'Address 2') {
								return null;
							} else {
								if (value == null || value.isEmpty) {
									return 'Please enter your $field';
								}
							}
							return null;
						},
						onSaved: (value) {
							setState(() {
								_addressSavedFields[field] = value;
							});
						},
					),
					const SizedBox(height: 12),
				],
			);
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Add a new address'),
			),
			body: Form(
				key: _formKey,
				child:  SingleChildScrollView(
					padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
					child: Column(
						children: <Widget>[
							for (String field in addressFields)
								_buildAddressField(field),
							SizedBox(
								width: double.infinity,
								child: ElevatedButton(
									style: ButtonStyle(
										padding: MaterialStateProperty.all(
											const EdgeInsets.symmetric(vertical: 10),
										),
									),
									onPressed: () async {
										if (_formKey.currentState!.validate()) {
											_formKey.currentState!.save();
											_addNewAddress();
										}
									}, 
									child: _loading
										?  const SizedBox(
												height: 19,
												width: 19,
												child: CircularProgressIndicator(
													color: Colors.white,
													strokeWidth: 2,
												),
											)
										: const Text('Submit', style: TextStyle(fontSize: 16),)
								),
							),
								SizedBox(
								width: double.infinity,
								child: TextButton(
									onPressed: () async {
										await Future.delayed(const Duration(milliseconds: 200));
										if (context.mounted) {
											Navigator.of(context).pop();
										}
									}, 
									child: const Text('Cancel')
								),
							),
						],
					),
				)
			)
		);
	}
}