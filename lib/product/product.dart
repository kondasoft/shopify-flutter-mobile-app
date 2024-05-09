import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:share_plus/share_plus.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'product_selected_variant_model.dart';
import 'product_gallery.dart';
import 'product_accordion.dart';
import 'product_rating_badge.dart';
import 'product_form.dart';
import 'product_recommendations.dart';


class ProductPage extends StatefulWidget {
	final String id;
	final String title;

	const ProductPage({super.key, required this.id, required this.title});

	@override
	State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> with SingleTickerProviderStateMixin {
	final ScrollController _listViewController = ScrollController();
	late AnimationController _fabController;
	late Animation<Offset> _fabOffset;
	String? _handle;

	@override
	void initState() {
		super.initState();

		_fabController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
		_fabOffset = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 4)).animate(_fabController);
		_fabController.forward();
  	}

	@override
	void dispose() {
		_fabController.dispose();
		super.dispose();
	}

	bool _handleScrollNotification(ScrollNotification notification) {
		if (notification.depth == 0) {
			if (notification is UserScrollNotification) {
				final UserScrollNotification userScroll = notification;
				
				switch (userScroll.direction) {
					case ScrollDirection.forward:
						if (userScroll.metrics.maxScrollExtent != userScroll.metrics.minScrollExtent) {
							if (userScroll.metrics.pixels > 500) {
								_fabController.reverse();
							} else {
								_fabController.forward();
							}
						}
						break;
					case ScrollDirection.reverse:
						if (userScroll.metrics.maxScrollExtent != userScroll.metrics.minScrollExtent) {
							_fabController.forward();
						}
						break;
					case ScrollDirection.idle:
						break;
				}
			}
		}
		return false;
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: Text(widget.title),
				actions: [
					IconButton(
						onPressed: () async {
							await Share.share('Check out ${widget.title} - ${dotenv.env['PRIMARY_DOMAIN']}/products/${_handle ?? ''}');
						}, 
						icon: const Icon(Icons.share)
					)
				],
			),
			body: ChangeNotifierProvider(
				create: (context) => SelectedVariantModel(),
				child: ListenableProvider<SelectedVariantModel>(
					create: (_) => SelectedVariantModel(),
					builder: (context, child) {
						return NotificationListener<ScrollNotification>(
							onNotification: _handleScrollNotification, 
							child: Query(
								options: QueryOptions(
									document: gql(r'''
										query product($id: ID) {
											product (id: $id) {
												id
												title
												handle
												descriptionHtml
												images (first: 50) {
													edges {
														node {
															id
															transformedSrc(maxWidth: 1200, maxHeight: 1200, crop: CENTER)
															altText
														}
													}
												},
												options (first: 50) {											
													id
													name
													values
												}
												variants (first: 50) {
													edges {
														node {
															id
															title
															availableForSale
															image {
																id
															}
															price {
																amount
																currencyCode
															}
															compareAtPrice {
																amount
																currencyCode
															}
															selectedOptions	{
																name
																value
															}										
														}
													}
												},
												metafields(identifiers: [
													{ namespace: "descriptors", key: "subtitle" }
													{ namespace: "reviews", key: "rating" }
													{ namespace: "reviews", key: "rating_count" }
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
										'id': widget.id,
									},
								),
								builder: (result, {fetchMore, refetch}) {
									if (result.isLoading) {
										return const Center(
											child: CircularProgressIndicator(semanticsLabel: 'Loading, please wait',),
										);
									}

									final Map product = result.data!['product'];

									final subtitleMetafield = product['metafields'].firstWhere((elem) => elem?['key'] == 'subtitle', orElse: () => null);
									String? subtitle;

									if (subtitleMetafield != null) {
										subtitle = subtitleMetafield['value'];
									}

									WidgetsBinding.instance.addPostFrameCallback((_) {
										setState(() {
											_handle = product['handle'];
										});
									});

									return ListView(
										controller: _listViewController,
										children: [
											ProductGallery(product: product),
											Column(
												children: [
													Padding(
														padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
														child: Column(
															children: [
																Text(product['title'], style: const TextStyle(fontSize: 20), textAlign: TextAlign.center,),
																const SizedBox(height: 6),
																ProductRatingBadge(
																	metafields: product['metafields'],
																	compact: false,
																),
																const SizedBox(height: 8),
																if (subtitle != null)
																	Column(
																		children: [
																			Padding(
																				padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 8),
																				child: Text(subtitle, style: const TextStyle(color: Colors.blueGrey, fontSize: 13), textAlign: TextAlign.center),
																			),
																			const SizedBox(height: 10)
																		],
																	),
																ProductForm(product: product),
																const SizedBox(height: 12),
																ProductAccordion(product: product),
															],
														)
													),
													ProductRecommandations(productId: product['id'])
												],
											)
										],
									);
								}
							)
						);
					}
				)
			),
			floatingActionButton: SlideTransition(
				position: _fabOffset,
				child: FloatingActionButton(
					onPressed: () async {
						await _listViewController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
						_fabController.forward();
					},
					mini: true,
					backgroundColor: Theme.of(context).primaryColor,
					foregroundColor: Colors.white,
					child: const Icon(Icons.arrow_upward),
				)
			)
		);
	}
}