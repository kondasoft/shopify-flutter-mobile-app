import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'customer_model.dart';

class CustomerLoginRegister extends StatefulWidget {
	const CustomerLoginRegister({super.key});

	@override
	State<CustomerLoginRegister> createState() => _CustomerLoginRegisterState();
}

class _CustomerLoginRegisterState extends State<CustomerLoginRegister> with SingleTickerProviderStateMixin {
	final _loginFormKey = GlobalKey<FormState>();
	final _registrationFormKey = GlobalKey<FormState>();
	final _forgotPasswordFormKey = GlobalKey<FormState>();
	late TabController _tabController;
	final TextEditingController _emailController = TextEditingController();
	final TextEditingController _passwordController = TextEditingController();
	final TextEditingController _firstNameController = TextEditingController();
	final TextEditingController _lastNameController = TextEditingController();
	bool _passwordObscure = true;
	bool _loading = false;

	Future<void> _login(BuildContext context) async {
		setState(() {
			_loading = true;
		});
		
		final client = GraphQLProvider.of(context).value;

		final result = await client.mutate(
			MutationOptions(
				document: gql(r'''
					mutation customerAccessTokenCreate ($input: CustomerAccessTokenCreateInput!) {
						customerAccessTokenCreate(input: $input)  {
							customerAccessToken {
								accessToken
								expiresAt
							}
							customerUserErrors {
								code
								field
								message
							}
						}
					}
				'''),
				variables: {
					'input': {
						'email': _emailController.text,
						'password': _passwordController.text,
					}
				},
			)
		);

		if (kDebugMode) {
			print(result);
		}

		List errors = result.data!['customerAccessTokenCreate']['customerUserErrors'];

		if (errors.isNotEmpty) {
			setState(() {
				_loading = false;
			});
			if (context.mounted) {
				ScaffoldMessenger.of(context).showSnackBar(SnackBar(
					content: Text('Error! Message: ${errors[0]['message']}')
				));
			}
			return;
		}

		Map accessToken = result.data!['customerAccessTokenCreate']['customerAccessToken'];

		final prefs = await SharedPreferences.getInstance();

		await prefs.setString('customer', jsonEncode({
			'accessToken': accessToken['accessToken'],
			'expiresAt': accessToken['expiresAt'],
		}));

		if (context.mounted) {
			context.read<CustomerModel>().getCustomer(context);

			ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
				content: Text('Sucessfully logged-in! Please wait...'),
				duration: Duration(seconds: 3),
			));
		}

		setState(() {
			_loading = false;
		});

		await Future.delayed(const Duration(seconds: 3));

		if (context.mounted) {
			Navigator.of(context).pop();
		}
	}

	Future<void> _register(BuildContext context) async {
		setState(() {
			_loading = true;
		});
		
		final client = GraphQLProvider.of(context).value;

		final result = await client.mutate(
			MutationOptions(
				document: gql(r'''
					mutation customerCreate ($input: CustomerCreateInput!) {
						customerCreate(input: $input)  {
							customer {
								id
							}
							customerUserErrors {
								code
								field
								message
							}
						}
					}
				'''),
				variables: {
					'input': {
						'firstName': _firstNameController.text,
						'lastName': _lastNameController.text,
						'email': _emailController.text,
						'password': _passwordController.text,
					}
				},
			)
		);

		if (kDebugMode) {
			print(result);
		}

		List errors = result.data!['customerCreate']['customerUserErrors'];

		if (errors.isNotEmpty) {
			setState(() {
				_loading = false;
			});
			if (context.mounted) {
				ScaffoldMessenger.of(context).showSnackBar(SnackBar(
					content: Text('Error! Message: ${errors[0]['message']}')
				));
			}
			return;
		}

		if (context.mounted) {
			_login(context);
		}
	}

	Future<void> _resetPassword(BuildContext context) async {
		setState(() {
			_loading = true;
		});
		
		final client = GraphQLProvider.of(context).value;

		final result = await client.mutate(
			MutationOptions(
				document: gql(r'''
					mutation customerRecover ($email: String!) {
						customerRecover(email: $email)  {
							customerUserErrors {
								code
								field
								message
							}
						}
					}
				'''),
				variables: {
					'email':  _emailController.text
				},
			)
		);

		if (kDebugMode) {
			print(result);
		}

		setState(() {
			_loading = false;
		});

		if (context.mounted) {
			Navigator.of(context).pop();
		}

		if (result.hasException) {
			if (context.mounted) {
				ScaffoldMessenger.of(context).showSnackBar(SnackBar(
					content: Text('Error! Message: ${result.exception!.graphqlErrors[0].message}')
				));
			}
			return;
		}

		List errors = result.data!['customerRecover']['customerUserErrors'];

		if (context.mounted) {
			if (errors.isNotEmpty) {
				ScaffoldMessenger.of(context).showSnackBar(SnackBar(
					content: Text('Error! Message: ${errors[0]['message']}')
				));
			} else {
				ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
					content: Text('We\'ve sent you an email with a link to update your password.')
				));
			}
		}
	}

	Future<void> _forgotPassword() async {
		await showModalBottomSheet<void>(
			isScrollControlled: true,
            context: context,
            builder: (BuildContext context) {
				return  StatefulBuilder(
          			builder: (BuildContext context, StateSetter setState) {
						return Form(
							key: _forgotPasswordFormKey,
							child:  Padding(
								padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom),
								child: Column(
									mainAxisAlignment: MainAxisAlignment.center,
									mainAxisSize: MainAxisSize.min,
									children: <Widget>[
										const Text('Reset your password', style: TextStyle(fontSize: 24)),
										const SizedBox(height: 6),
										const Text('We will send you an email to reset your password', style: TextStyle()),
										const SizedBox(height: 18),
										TextFormField(
											autofocus: true,
											controller: _emailController,
											keyboardType: TextInputType.emailAddress,
											decoration: const InputDecoration(
												border: OutlineInputBorder(), 
												labelText: "Email"
											),
											validator: (value) {
												if (value == null || value.isEmpty) {
													return 'Please enter your email';
												}
												return null;
											},
										),
										const SizedBox(height: 12),
										SizedBox(
											width: double.infinity,
											child: ElevatedButton(
												style: ButtonStyle(
													padding: MaterialStateProperty.all(
														const EdgeInsets.symmetric(vertical: 10),
													),
												),
												onPressed: () async {
													if (_forgotPasswordFormKey.currentState!.validate()) {
														setState((){
															_loading = true;
														});
														_resetPassword(context);
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
										const SizedBox(height: 8),
									],
								),
							)
						);
					}
				);
            },
		);
	}

	@override
	void initState() {
		super.initState();
		_tabController = TabController(vsync: this, length: 2);
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Login or Register'),
				bottom: TabBar(
					controller: _tabController,
					tabs: const [
						Tab(text: 'Login',),
						Tab(text: 'Register'),
					],
					labelStyle: const TextStyle(color: Colors.white),
					unselectedLabelStyle: const TextStyle(color: Colors.white),
					overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(.25)),
					indicatorColor: Colors.white,
				),
			),
			body: TabBarView(
				controller: _tabController,
				children: [
					Form(
						key: _loginFormKey,
						child: ListView(
							padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
							children: [
								const Text('Login', style: TextStyle(fontSize: 24), textAlign: TextAlign.center,),
								const SizedBox(height: 18),
								TextFormField(
									autofocus: true,
									controller: _emailController,
									keyboardType: TextInputType.emailAddress,
									decoration: const InputDecoration(
										border: OutlineInputBorder(), 
										labelText: "Email"
									),
									validator: (value) {
										if (value == null || value.isEmpty) {
											return 'Please enter your email';
										}
										return null;
									},
								),
								const SizedBox(height: 16,),
								TextFormField(
									controller: _passwordController,
									obscureText: _passwordObscure,
									decoration: InputDecoration(
										border: const OutlineInputBorder(), 
										labelText: "Password",
										suffixIcon: IconButton(
											icon: Icon( _passwordObscure ? Icons.visibility_off : Icons.visibility),
											color: Colors.grey,
											iconSize: 22,
											onPressed: () {
												setState(() {
													_passwordObscure = !_passwordObscure;
												});
											},
										),
									),
									validator: (value) {
										if (value == null || value.isEmpty) {
											return 'Please enter your password';
										}
										return null;
									},
								),
								SizedBox(
									width: double.infinity,
									child: TextButton(
										onPressed: () async {
											await Future.delayed(const Duration(milliseconds: 200));
											_forgotPassword();
										}, 
										child: const  Align(
											alignment: Alignment.centerLeft,
											child: Text('Forgot your password?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Colors.black54),)
										)
									),
								),
								const SizedBox(height: 4),
								SizedBox(
									width: double.infinity,
									child: ElevatedButton(
										style: ButtonStyle(
											padding: MaterialStateProperty.all(
												const EdgeInsets.symmetric(vertical: 10),
											),
										),
										onPressed: () async {
											if (_loginFormKey.currentState!.validate()) {
												_login(context);
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
											: const Text('Sign In', style: TextStyle(fontSize: 16),)
									),
								),
								SizedBox(
									width: double.infinity,
									child: TextButton(
										onPressed: () async {
											await Future.delayed(const Duration(milliseconds: 200));
											_tabController.animateTo(1);
										}, 
										child: const Text('Create account')
									),
								)
							]
						)
					),
					Form(
						key: _registrationFormKey,
						child: ListView(
							padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
							children: [
								const Text('Create account', style: TextStyle(fontSize: 24), textAlign: TextAlign.center,),
								const SizedBox(height: 18),
								TextFormField(
									autofocus: true,
									controller: _firstNameController,
									decoration: const InputDecoration(
										border: OutlineInputBorder(), labelText: "First name"
									),
									validator: (value) {
										if (value == null || value.isEmpty) {
											return 'Please enter your first name';
										}
										return null;
									},
								),
								const SizedBox(height: 16,),
								TextFormField(
									controller: _lastNameController,
									decoration: const InputDecoration(
										border: OutlineInputBorder(), labelText: "Last name"
									),
									validator: (value) {
										if (value == null || value.isEmpty) {
											return 'Please enter your last name';
										}
										return null;
									},
								),
								const SizedBox(height: 16,),
								TextFormField(
									controller: _emailController,
									keyboardType: TextInputType.emailAddress,
									decoration: const InputDecoration(
										border: OutlineInputBorder(), labelText: "Email"
									),
									validator: (value) {
										if (value == null || value.isEmpty) {
											return 'Please enter your email';
										}
										return null;
									},
								),
								const SizedBox(height: 16,),
								TextFormField(
									controller: _passwordController,
									obscureText: _passwordObscure,
									decoration: InputDecoration(
										border: const OutlineInputBorder(), 
										labelText: "Password",
										suffixIcon: IconButton(
											icon: Icon( _passwordObscure ? Icons.visibility_off : Icons.visibility),
											color: Colors.grey,
											iconSize: 22,
											onPressed: () {
												setState(() {
													_passwordObscure = !_passwordObscure;
												});
											},
										),
									),
									validator: (value) {
										if (value == null || value.isEmpty) {
											return 'Please enter your password';
										}
										return null;
									},
								),
								const SizedBox(height: 12),
								SizedBox(
									width: double.infinity,
									child: ElevatedButton(
										style: ButtonStyle(
											padding: MaterialStateProperty.all(
												const EdgeInsets.symmetric(vertical: 10),
											),
										),
										onPressed: () {
											if (_registrationFormKey.currentState!.validate()) {
												_register(context);
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
											: const Text('Create', style: TextStyle(fontSize: 16),)
									),
								),
								SizedBox(
									width: double.infinity,
									child: TextButton(
										onPressed: () async {
											await Future.delayed(const Duration(milliseconds: 200));
											_tabController.animateTo(0);
										}, 
										child: const Text('Login')
									),
								)
							]
						)
					)
				]
			)
		);
  	}
}