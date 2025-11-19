import 'package:diurecycle/Screen/home.dart';
import 'package:diurecycle/services/auth_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  
  String _fullName = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  void _attemptSignup() async {
    if (_formKey.currentState!.validate() && _agreeToTerms) {
      _formKey.currentState!.save();
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Updated to pass fullName to the service
        User? user = await _authService.createUserWithEmailAndPassword(
          _email,
          _password,
          context,
          fullName: _fullName,
        );
        
        if (user != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', true);
          SnackBar(
              content: Text('Account created! Please verify your email.'),
              backgroundColor: Colors.green.shade400,
            );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'An error occurred during signup';
        
        // Handle specific Firebase Auth errors
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'This email is already registered';
            break;
          case 'invalid-email':
            errorMessage = 'Please enter a valid email address';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Email/password accounts are not enabled';
            break;
          case 'weak-password':
            errorMessage = 'Please choose a stronger password';
            break;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade400,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: Colors.orange.shade400,
        ),
      );
    }
  }

  void _viewTermsAndPrivacy() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Terms & Privacy',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.green.shade800,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Terms & Conditions
                        Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green.shade800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Last updated: November 10, 2025',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildSectionTitle('1. Acceptance of Terms'),
                        Text(
                          'By accessing and using DIU Recycle, you accept and agree to be bound by the terms and provisions of this agreement. This app is exclusively for Daffodil International University (DIU) students.',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                        SizedBox(height: 12),
                        _buildSectionTitle('2. User Eligibility'),
                        Text(
                          'To use DIU Recycle, you must:\n\n'
                          '• Be a current student of Daffodil International University\n'
                          '• Provide a valid DIU email address for verification\n'
                          '• Be at least 18 years old or have parental consent\n'
                          '• Agree to conduct transactions responsibly and honestly',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                        SizedBox(height: 12),
                        _buildSectionTitle('3. Product Listings'),
                        Text(
                          'When listing products, users must:\n\n'
                          '• Provide accurate product descriptions and images\n'
                          '• Set fair and honest prices\n'
                          '• Not list prohibited items (weapons, drugs, counterfeit goods)\n'
                          '• Update or remove listings when items are sold\n'
                          '• Meet buyers on campus or in safe public locations',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                        SizedBox(height: 12),
                        _buildSectionTitle('4. User Conduct'),
                        Text(
                          'Users are expected to maintain respectful communication, complete transactions as agreed, and report any suspicious or fraudulent activity. Harassment, spam, or misuse of the platform will result in account suspension.',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                        SizedBox(height: 12),
                        _buildSectionTitle('5. Liability'),
                        Text(
                          'DIU Recycle acts as a platform to connect buyers and sellers. We are not responsible for the quality, safety, or legality of items listed, the accuracy of listings, or the ability of users to complete transactions. All transactions are between users.',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                        SizedBox(height: 12),
                        _buildSectionTitle('6. Termination'),
                        Text(
                          'We reserve the right to suspend or terminate accounts that violate these terms, engage in fraudulent activity, or compromise the safety of the community.',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                        SizedBox(height: 12),
                        _buildSectionTitle('7. Contact'),
                        Text(
                          'For questions about these Terms & Conditions, please contact us at syedsabbirahmed.contact@gmail.com',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                        SizedBox(height: 24),
                        Divider(),
                        SizedBox(height: 16),
                        // Privacy Policy
                        Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green.shade800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Last updated: November 10, 2025',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildSectionTitle('Information We Collect'),
                        Text(
                          'We collect the following information to provide you with our services:\n\n'
                          '• Account Information: Name, DIU email, student ID for verification\n'
                          '• Profile Data: Profile picture, contact details, location\n'
                          '• Product Listings: Photos, descriptions, prices, categories\n'
                          '• Messages: Chat history with other users via Firebase\n'
                          '• Device Information: Device type, OS version for push notifications',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                        SizedBox(height: 12),
                        _buildSectionTitle('How We Use Your Information'),
                        Text(
                          '• Verify your DIU student status\n'
                          '• Enable product listings and marketplace features\n'
                          '• Facilitate real-time messaging between buyers and sellers\n'
                          '• Send push notifications for messages and updates\n'
                          '• Improve app performance and user experience\n'
                          '• Prevent fraud and ensure community safety',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                        SizedBox(height: 12),
                        _buildSectionTitle('Data Storage & Security'),
                        Text(
                          'Your data is securely stored using Firebase (Google Cloud Platform) with industry-standard encryption. Images are hosted on Cloudinary CDN. We use Firebase Authentication to protect your account with secure password hashing and email verification.',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                        SizedBox(height: 12),
                        _buildSectionTitle('Data Sharing'),
                        Text(
                          'We do NOT sell your personal information. Your data is shared only in the following ways:\n\n'
                          '• With Other Users: Your profile, listings, and messages visible to other verified DIU students\n'
                          '• Service Providers: Firebase (authentication & database), Cloudinary (image storage), OneSignal (notifications)\n'
                          '• Legal Requirements: If required by law or to protect user safety',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                        SizedBox(height: 12),
                        _buildSectionTitle('Your Rights'),
                        Text(
                          '• Access your personal data at any time\n'
                          '• Update or correct your profile information\n'
                          '• Delete your account and associated data\n'
                          '• Opt-out of push notifications (in app settings)\n'
                          '• Request a copy of your data',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                        SizedBox(height: 12),
                        _buildSectionTitle('Cookies & Tracking'),
                        Text(
                          'We use Firebase Analytics to understand app usage patterns. No third-party advertising cookies are used. Location data is only collected when you enable location services for product listings.',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                        SizedBox(height: 12),
                        _buildSectionTitle('Children\'s Privacy'),
                        Text(
                          'DIU Recycle is intended for university students aged 18+. We do not knowingly collect data from children under 18 without parental consent.',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                        SizedBox(height: 12),
                        _buildSectionTitle('Contact Us'),
                        Text(
                          'For privacy concerns or data requests, contact us at syedsabbirahmed.contact@gmail.com',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                        SizedBox(height: 24),
                        Divider(),
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.language, size: 18, color: Colors.green.shade700),
                                  SizedBox(width: 8),
                                  Text(
                                    'View Full Terms Online',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'You can also view the complete Terms & Conditions and Privacy Policy on our website:',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                              SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  try {
                                    final Uri url = Uri.parse('https://diurecycle.vercel.app/');
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url, mode: LaunchMode.externalApplication);
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Could not open the website. Please try again later.'),
                                            backgroundColor: Colors.orange.shade400,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error opening website: ${e.toString()}'),
                                          backgroundColor: Colors.red.shade400,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Text(
                                  'https://diurecycle.vercel.app/',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.green.shade700,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.green.shade700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back, color: Colors.green.shade800),
                      ),
                    ),
                    
                    // App Logo
                    SizedBox(
                      height: 120,
                      width: 120,                   
                      child: Center(
                        child: Image.asset(
                            'lib/assets/logo.png',
                            height: 100, // Adjust size as needed
                            width: 100,
                            fit: BoxFit.contain,
                          ),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    
                    // App Title & Slogan
                    Text(
                      'DIU Recycle',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Buy, sell, reduce, reuse!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32.0),
                    
                    // Sign Up Title
                    Text(
                      'Create Your Account',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Join the sustainable campus movement',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32.0),
                    
                    // Full Name Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                        prefixIcon: Icon(Icons.person_outline, color: Colors.green.shade600),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: Colors.green.shade400, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        if (value.trim().split(' ').length < 2) {
                          return 'Please enter your full name (first and last)';
                        }
                        return null;
                      },
                      onSaved: (value) => _fullName = value!.trim(),
                    ),
                    SizedBox(height: 16.0),
                    
                    // Email Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your university email',
                        prefixIcon: Icon(Icons.email_outlined, color: Colors.green.shade600),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: Colors.green.shade400, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        
                        if (!value.toLowerCase().contains('@')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                      onSaved: (value) => _email = value!.trim(),
                    ),
                    SizedBox(height: 16.0),
                    
                    // Password Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Create a password',
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.green.shade600),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: Colors.green.shade400, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible 
                                ? Icons.visibility 
                                : Icons.visibility_off,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_isPasswordVisible,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                          return 'Password must include at least one special character';
                        }
                        return null;
                      },
                      onSaved: (value) => _password = value!,
                      onChanged: (value) => _password = value,
                    ),
                    SizedBox(height: 16.0),
                    
                    // Confirm Password Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        hintText: 'Confirm your password',
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.green.shade600),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: Colors.green.shade400, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible 
                                ? Icons.visibility 
                                : Icons.visibility_off,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_isConfirmPasswordVisible,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _password) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      onSaved: (value) => _confirmPassword = value!,
                    ),
                    SizedBox(height: 20.0),
                    
                    // Terms and Conditions Checkbox with improved layout
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Theme(
                          data: ThemeData(
                            checkboxTheme: CheckboxThemeData(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          child: Checkbox(
                            value: _agreeToTerms,
                            activeColor: Colors.green.shade600,
                            onChanged: (value) {
                              setState(() {
                                _agreeToTerms = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: RichText(
                              text: TextSpan(
                                text: 'I agree to the ',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = _viewTermsAndPrivacy,
                                  ),
                                  TextSpan(
                                    text: ' and ',
                                  ),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = _viewTermsAndPrivacy,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.0),
                    
                    // Sign Up Button with loading state
                    _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: Colors.green.shade600,
                              strokeWidth: 3,
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _attemptSignup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              elevation: 2,
                              shadowColor: Colors.green.shade200,
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                            ),
                            child: Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    SizedBox(height: 24.0),
                    
                    // Login option
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0),
                    
                    // App Slogan
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        'Your small actions create a big impact on campus sustainability!',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}