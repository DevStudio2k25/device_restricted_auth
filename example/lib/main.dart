import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_restricted_auth/device_restricted_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (you need to add your firebase_options.dart)
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Device Restricted Auth Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Initialize the coordinator
  late final DeviceRestrictionCoordinator _coordinator;

  @override
  void initState() {
    super.initState();

    // Choose device ID provider based on platform
    final deviceIdProvider = Platform.isAndroid
        ? AndroidDeviceIdProvider()
        : WindowsDeviceIdProvider();

    // Create the coordinator
    _coordinator = DeviceRestrictionCoordinator(
      deviceRepository: FirestoreDeviceRepository(),
      deviceIdProvider: deviceIdProvider,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handle user signup with device restriction
  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Step 1: Check if device is available for new account
      await _coordinator.verifyDeviceForSignup();

      // Step 2: Create Firebase account
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Step 3: Initialize device document
      await _coordinator.initializeDeviceDocument(credential.user!.uid);

      // Step 4: Bind current device to this account
      await _coordinator.verifyAndBindDevice(credential.user!.uid);

      setState(() {
        _successMessage = '✅ Signup successful! Device bound permanently.';
      });
    } on DeviceAlreadyBoundException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = 'Auth Error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Handle user login with device verification
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Step 1: Sign in with Firebase
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Step 2: Verify device binding
      await _coordinator.verifyAndBindDevice(credential.user!.uid);

      setState(() {
        _successMessage = '✅ Login successful!';
      });
    } on DeviceMismatchException catch (e) {
      // Device mismatch - sign out immediately
      await FirebaseAuth.instance.signOut();

      setState(() {
        _errorMessage = e.message;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = 'Auth Error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Restricted Auth'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Title
              Text(
                'Device Binding Demo',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              // Platform info
              Text(
                'Platform: ${Platform.isAndroid ? "Android" : "Windows Desktop"}',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              // Email field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Password field
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Signup button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSignup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign Up (Bind Device)'),
              ),

              const SizedBox(height: 12),

              // Login button
              OutlinedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Login (Verify Device)'),
              ),

              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),

              // Success message
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _successMessage!,
                    style: TextStyle(color: Colors.green.shade900),
                  ),
                ),

              const SizedBox(height: 24),

              // Info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How it works:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text('1. Sign up binds this device permanently'),
                      const Text('2. Login verifies device matches'),
                      const Text('3. Each account: 1 Android + 1 Desktop'),
                      const Text('4. Device change is NOT allowed'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
