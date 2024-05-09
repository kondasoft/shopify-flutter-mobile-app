import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import 'drawer.dart';
import 'search.dart';
import 'collection/collection.dart';
import 'cart/cart_model.dart';
import 'cart/cart.dart';
import 'customer/customer_model.dart';

const seedColor = Colors.blue;
final primaryColor = Colors.blue.shade700;
const shadowColor = Colors.black;

void main() async {
	await dotenv.load();
	await initHiveForFlutter();
	runApp(
		MultiProvider(
			providers: [
				ChangeNotifierProvider(create: (_) => CartModel()),
				ChangeNotifierProvider(create: (_) => CustomerModel()),
			],
			child: const MyApp(),
		)
	);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
			client: ValueNotifier<GraphQLClient>(
				GraphQLClient(
					link: HttpLink(
						"${dotenv.env['PERMANENT_DOMAIN']}/api/${dotenv.env['API_VERSION']}/graphql.json", 
						defaultHeaders: {
							'X-Shopify-Storefront-Access-Token': dotenv.env['API_KEY'].toString()
						}
					),
					cache: GraphQLCache(store: HiveStore()),
				),
			),
			child: MaterialApp(
				title: dotenv.env['STORE_NAME']!,
				theme: ThemeData(
					colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
					primaryColor: primaryColor,
					shadowColor: primaryColor.withOpacity(.25),
					useMaterial3: true,
					appBarTheme: AppBarTheme.of(context).copyWith(
						backgroundColor: primaryColor,
						foregroundColor: Colors.white,
						elevation: 5,
						shadowColor: shadowColor.withOpacity(.5),
					),
					cardTheme: CardTheme.of(context).copyWith(
						surfaceTintColor: Colors.transparent,
						shadowColor: shadowColor.withOpacity(.5),
					),
					expansionTileTheme: ExpansionTileTheme.of(context).copyWith(
						backgroundColor: primaryColor.withOpacity(.05),
						collapsedBackgroundColor: Colors.transparent
					)
				),
				debugShowCheckedModeBanner: false,
				home: const MyHomePage(),
			)
		);
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
	@override
	void initState() {
		super.initState();
		WidgetsBinding.instance.addPostFrameCallback((_) async {
			context.read<CartModel>().getCart(context);
			context.read<CustomerModel>().getCustomer(context);
		});
	}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(dotenv.env['STORE_NAME'].toString()),
				actions: [
					IconButton(
						onPressed: () {
							Future.delayed(const Duration(milliseconds: 200)).then((_) => {
								Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SearchPage()))
							});
						}, 
						icon: const Icon(Icons.search)
					),
					IconButton(
						onPressed: () {
							Future.delayed(const Duration(milliseconds: 200)).then((_) => {
								Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CartPage()))
							});
						}, 
						icon: Stack(
							clipBehavior: Clip.none,
							children: [
								const Icon(
									Icons.shopping_cart_outlined, semanticLabel: 'Cart',
								),
								if (context.watch<CartModel>().count > 0)
									Positioned(
										top: 0,
										right: -6,
										child: CircleAvatar(
											radius: 8,
											backgroundColor: Colors.yellow.shade900,
											child: Text(context.watch<CartModel>().count.toString(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),),
										),
									)
							],
						)
					),
					const SizedBox(width: 6,)
				],
      ),
			drawer: const MyDrawer(),
      body: Query(
				options: QueryOptions(
					document: gql(r"""
						query collections() {
							collections (first: 50) {
								edges {
									node {
										id,
										title,
										handle,
										description,
										image {
											transformedSrc(maxWidth: 900, maxHeight: 720, crop: CENTER)
											altText
										}
									}
								}
							}
						}
					"""),
				),
				builder: (result, {fetchMore, refetch}) {
					if (result.isLoading) {
						return const Center(
							child: CircularProgressIndicator(semanticsLabel: 'Loading, please wait',),
						);
					}

					return GridView.count(
						crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
						childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.1 : 1.075,
						padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
						children: [
							for (dynamic edge in result.data!['collections']['edges'])
								Card(
									margin: const EdgeInsets.all(6),
									child: Stack(
										children: <Widget>[
											Column(
												children: [
													ClipRRect(
														borderRadius: const BorderRadius.vertical(top: Radius.circular(4.0)),
														child: CachedNetworkImage(
															imageUrl: edge['node']['image']['transformedSrc'] ?? '',
															placeholder: (context, url) => Container(
																color: Colors.grey.shade100,
															),
															width: MediaQuery.of(context).size.width > 600 
																? MediaQuery.of(context).size.width / 3 - 18
																: MediaQuery.of(context).size.width / 2 - 18,
															height: MediaQuery.of(context).size.width > 600 
																? MediaQuery.of(context).size.width / 3 * .75 - 18
																: MediaQuery.of(context).size.width / 2 * .75 - 18,
															fit: BoxFit.cover,
														),
													),
													Padding(
														padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
														child: Column(
															children: [
																Text(edge['node']['title'], style: const TextStyle())
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
																Navigator.of(context).push(MaterialPageRoute(builder: (context) => CollectionPage(
																	id: edge['node']['id'],
																	title: edge['node']['title']
																)));
															}
														},
													)
												)
											)
										]
									),
								)
						],
					);
				}),
    );
  }
}
