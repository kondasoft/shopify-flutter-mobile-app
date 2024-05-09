import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'collection/collection.dart';
import 'product/product.dart';
import 'customer/customer_model.dart';
import 'customer/customer_login_register.dart';
import 'customer/customer_orders.dart';
import 'customer/customer_addresses.dart';

final List<Map> socialIcons = [
	{ 'handle': 'instagram', 'title': "Instagram", 'url': dotenv.env['SOCIAL_INSTAGRAM'] },
	{ 'handle': 'facebook', 'title': "Facebook", 'url': dotenv.env['SOCIAL_FACEBOOK'] },
	{ 'handle': 'tiktok', 'title': "Tiktok", 'url': dotenv.env['SOCIAL_TIKTOK'] },
	{ 'handle': 'x', 'title': "Twitter", 'url': dotenv.env['SOCIAL_X'] },
	{ 'handle': 'youtube', 'title': "YouTube", 'url': dotenv.env['SOCIAL_YOUTUBE'] }
];
class MyDrawer extends StatefulWidget {
	const MyDrawer({super.key});

	@override
	State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
	bool _showAccountMenu = false;

	void _menuItemOnTap(BuildContext context, Map item) async {
		await Future.delayed(const Duration(milliseconds: 200));

		switch (item['type']) {
			case 'COLLECTION':
				if (context.mounted) {
					Navigator.of(context).push(MaterialPageRoute(builder: (context) => CollectionPage(
						title: item['title'],
						id: item['resourceId'],
					)));
				}
				break;
			case 'PRODUCT':
				if (context.mounted) {
					Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProductPage(
						title: item['title'],
						id: item['resourceId'],
					)));
				}
				break;
			case 'HTTP':
				launchUrl(Uri.parse(item['url']));
				break;
			default:
		}
	}

	@override
	Widget build(BuildContext context) {
		return Drawer(
			child: Column(
				children: [
					if (context.watch<CustomerModel>().customer == null)
						DrawerHeader(
							decoration: BoxDecoration(
								gradient: LinearGradient(
									colors: [Theme.of(context).primaryColor.withOpacity(.8), Theme.of(context).primaryColor],
									begin: Alignment.topCenter,
									end: Alignment.bottomCenter
								)
							),
							child: Align(
								alignment: Alignment.center,
								child: Column(
									mainAxisAlignment: MainAxisAlignment.center,
									children: [
										const Text('Welcome guest', style: TextStyle(color: Colors.white, fontSize: 18),),
										Text('Please login or register', style: TextStyle(color: Colors.white.withOpacity(.75)),),
										const SizedBox(height: 10),
										Row(
											mainAxisAlignment: MainAxisAlignment.center,
											children: [
												ElevatedButton(
													onPressed: () async {
														await Future.delayed(const Duration(milliseconds: 200));
														if (context.mounted) {
															Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CustomerLoginRegister()));
														}
													}, 
													child: const Text('Login or Register')
												),
											],
										),
										const SizedBox(height: 4),
									],
								),
							),
						),
					if (context.watch<CustomerModel>().customer != null)
						UserAccountsDrawerHeader(
							decoration: BoxDecoration(
								gradient: LinearGradient(
									colors: [Theme.of(context).primaryColor.withOpacity(.8), Theme.of(context).primaryColor],
									begin: Alignment.topCenter,
									end: Alignment.bottomCenter
								)
							),
							margin: EdgeInsets.zero,
							accountName: Text(
								'${context.read<CustomerModel>().customer!['firstName']} ${context.read<CustomerModel>().customer!['lastName']}'
							),
							accountEmail: Text(context.read<CustomerModel>().customer!['email']),
							currentAccountPicture: CachedNetworkImage(
								imageUrl: 'https://www.gravatar.com/avatar/${md5.convert(utf8.encode(context.read<CustomerModel>().customer!['email']))}?s=240&d=mp',
								imageBuilder: (context, imageProvider) => Container(
									decoration: BoxDecoration(
										shape: BoxShape.circle,
										image: DecorationImage(
											image: imageProvider, 
											fit: BoxFit.cover
										),
									),
								)
							),
							onDetailsPressed: () {
								setState(() {
									_showAccountMenu = !_showAccountMenu;
								});
							},
						),
					if (!_showAccountMenu)
						Query(
							options: QueryOptions(
								document: gql(r"""
									query menu($handle: String!) {
										menu (handle: $handle) {
											itemsCount
											title
											items {
												title
												url
												type
												resourceId
												items {
													title
													url
													type
													resourceId
												}
											}
										}
									}
								"""),
								variables: {
									'handle': dotenv.env['MAIN_MENU_HANDLE'],
								}
							),
							builder: (result, {fetchMore, refetch}) {
								if (result.isLoading) {
									return const Expanded(
										child: Center(
											child: CircularProgressIndicator(semanticsLabel: 'Loading, please wait',),
										)
									);
								}

								if (kDebugMode) {
									print(result);
								}

								if (result.data!['menu'] == null) {
									return const Text('Menu not found!');
								}

								List menuItems = result.data!['menu']['items'];

								return Expanded(
									child: ListView(
										padding: const EdgeInsets.fromLTRB(0, 10, 0, 16),
										children: menuItems.map((item) {
											if (item['title'] == '-') {
												return const Divider();
											} else if (item['items'].isEmpty) {
												return ListTile( 
													title: Text(item['title']),
													trailing: item['type'] == 'HTTP'
														? const Padding(
															padding: EdgeInsets.only(right: 5),
															child: Icon(Icons.open_in_new, size: 18,),
														)
														: null,
													// subtitle: Text(item['type']),
													onTap: () => _menuItemOnTap(context, item)
												);
											} else {
												return Theme(
													data: Theme.of(context).copyWith(
														dividerColor: Colors.transparent
													),
													child: ExpansionTile(
														title: Text(item['title']),
														children: [
															for (Map item in item['items'])
																ListTile( 
																	dense: true,
																	title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.w400),),
																	onTap: () => _menuItemOnTap(context, item),
																),
														],
													)
												);
											}
										}).toList()
									)
								);
							}
						),
					if (_showAccountMenu)
						Expanded(
							child: ListView(
								padding: const EdgeInsets.fromLTRB(0, 10, 0, 16),
								children: [
									ListTile( 
										title: const Text('Orders'),
										leading: const Icon(Icons.list),
										onTap: () async {
											await Future.delayed(const Duration(milliseconds: 200));
											if (context.mounted) {
												Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CustomerOrders()));
											}
										}
									),
									ListTile( 
										title: const Text('Addresses'),
										leading: const Icon(Icons.home_outlined),
										onTap: () async{
											await Future.delayed(const Duration(milliseconds: 200));
											if (context.mounted) {
												Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CustomerAddresses()));
											}
										}
									),
									ListTile( 
										title: const Text('Logout'),
										leading: const Icon(Icons.exit_to_app),
										onTap: () async {
											final prefs = await SharedPreferences.getInstance();
											await prefs.remove('customer');

											if (context.mounted) {
												await context.read<CustomerModel>().getCustomer(context);
											}

											if (context.mounted) {
												Navigator.of(context).pop();
												ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
													content: Text('Sucessfully logged-out!'),
												));
											}

											setState(() {
												_showAccountMenu = false;
											});
										}
									)
								]
							)
						),
					 	Container(
							decoration: BoxDecoration(
								border: Border(top: BorderSide(
									color: Colors.black.withOpacity(.05)
								))
							),
							padding: const EdgeInsets.only(bottom: 10),
							child: Row(
								mainAxisAlignment: MainAxisAlignment.center,
								children: [
									for (Map item in socialIcons)
										IconButton(
											onPressed: () async {
												await Future.delayed(const Duration(milliseconds: 200));
												launchUrl(Uri.parse(item['url']));
											}, 
											icon: SvgPicture.asset(
												'assets/social-icons/${item['handle']}.svg',
												semanticsLabel: item['title'],
												width: 20,
												height: 20,
											),
										)
									],
								)
						)
				],
			),
		);
	}
}