import 'package:flutter/material.dart';
import 'package:kpostal/kpostal.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'dart:async';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _detailAddressFocusNode = FocusNode();
  
  String? selectedYear;
  String? selectedMonth;
  String? selectedDay;
  bool isMale = true;
  Timer? _emailDebounce;
  bool _isEmailChecking = false;
  bool _isEmailAvailable = true;
  bool _isDetailAddressEnabled = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _detailAddressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _emailController.addListener(_onEmailChanged);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
    _addressController.addListener(_validateForm);
    _detailAddressController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _emailDebounce?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _detailAddressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _detailAddressFocusNode.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    _emailDebounce?.cancel();
    if (_emailController.text.isNotEmpty && _isValidEmail(_emailController.text)) {
      setState(() => _isEmailChecking = true);
      _emailDebounce = Timer(const Duration(milliseconds: 500), () {
        _checkEmailDuplicate(_emailController.text);
      });
    }
    _validateForm();
  }

  Future<void> _checkEmailDuplicate(String email) async {
    try {
      final isDuplicate = await context.read<AuthService>().checkEmailDuplicate(email);
      setState(() {
        _isEmailAvailable = !isDuplicate;
        _isEmailChecking = false;
      });
      _validateForm();
    } catch (e) {
      setState(() {
        _isEmailChecking = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _formKey.currentState?.validate() ?? false &&
          _nameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _isEmailAvailable &&
          !_isEmailChecking &&
          _passwordController.text.isNotEmpty &&
          _confirmPasswordController.text.isNotEmpty &&
          _addressController.text.isNotEmpty &&
          selectedYear != null &&
          selectedMonth != null &&
          selectedDay != null &&
          _isValidDate() &&
          _passwordController.text == _confirmPasswordController.text;
    });
  }

  bool _isValidDate() {
    if (selectedYear == null || selectedMonth == null || selectedDay == null) {
      return false;
    }

    try {
      final year = int.parse(selectedYear!);
      final month = int.parse(selectedMonth!);
      final day = int.parse(selectedDay!);
      
      final date = DateTime(year, month, day);
      final now = DateTime.now();
      
      // 날짜가 유효하고 현재 날짜보다 이전인지 확인
      return date.year == year && 
             date.month == month && 
             date.day == day &&
             date.isBefore(now);
    } catch (e) {
      return false;
    }
  }

  List<String> _getDaysInMonth(String? year, String? month) {
    if (year == null || month == null) return List.generate(31, (i) => (i + 1).toString().padLeft(2, '0'));
    
    final daysInMonth = DateTime(int.parse(year), int.parse(month) + 1, 0).day;
    return List.generate(daysInMonth, (i) => (i + 1).toString().padLeft(2, '0'));
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPassword(String password) {
    // 최소 8자, 하나 이상의 문자와 숫자 포함
    return RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$').hasMatch(password);
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return '이름을 입력해주세요';
    }
    if (value.length < 2) {
      return '이름은 2자 이상이어야 합니다';
    }
    if (!RegExp(r'^[가-힣a-zA-Z\s]+$').hasMatch(value)) {
      return '이름은 한글 또는 영문만 입력 가능합니다';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요';
    }
    if (!_isValidEmail(value)) {
      return '올바른 이메일 형식이 아닙니다';
    }
    if (!_isEmailAvailable) {
      return '이미 사용 중인 이메일입니다';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요';
    }
    if (value.length < 8) {
      return '비밀번호는 8자 이상이어야 합니다';
    }
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$').hasMatch(value)) {
      return '비밀번호는 영문, 숫자, 특수문자를 포함해야 합니다';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 다시 입력해주세요';
    }
    if (value != _passwordController.text) {
      return '비밀번호가 일치하지 않습니다';
    }
    return null;
  }

  String? _validateAddress() {
    if (_addressController.text.isEmpty) {
      return '주소를 입력해주세요';
    }
    if (_detailAddressController.text.isEmpty) {
      return '상세 주소를 입력해주세요';
    }
    return null;
  }

  Future<void> _searchAddress() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KpostalView(
          callback: (Kpostal result) {
            setState(() {
              _addressController.text = result.address;
              _isDetailAddressEnabled = true;
              // 상세주소 필드로 포커스 이동
              _detailAddressFocusNode.requestFocus();
            });
          },
        ),
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = '입력 정보를 다시 확인해주세요';
      });
      return;
    }

    if (!_isValidDate()) {
      setState(() {
        _errorMessage = '올바른 생년월일을 선택해주세요';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final birthDate = '$selectedYear-$selectedMonth-$selectedDay';
      final address = _addressController.text;
      final detailAddress = _detailAddressController.text;

      await context.read<AuthService>().signup(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            isMale: isMale,
            birthDate: birthDate,
            address: address,
            detailAddress: detailAddress,
            disabilityType: 'pending',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '회원가입이 완료되었습니다',
              style: TextStyle(fontFamily: 'NotoSansKR'),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DisabilitySelectionScreen(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _errorMessage ?? '회원가입 중 오류가 발생했습니다',
            style: const TextStyle(fontFamily: 'NotoSansKR'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildErrorBanner() {
    if (_errorMessage == null) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontFamily: 'NotoSansKR',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    if (!_isLoading) return const SizedBox.shrink();

    return Container(
      color: Colors.black54,
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  '회원가입 처리 중...',
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: const Color(0xFF4A55E7),
            title: const Text(
              '회원 가입',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'NotoSansKR',
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            elevation: 0,
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildErrorBanner(),
                    _buildInputField(
                      '이름',
                      _nameController,
                      '(예시) 홍길동',
                      validator: _validateName,
                      onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                    ),
                    const SizedBox(height: 24),
                    _buildGenderSelection(),
                    const SizedBox(height: 24),
                    _buildEmailField(),
                    const SizedBox(height: 24),
                    _buildBirthDateSelection(),
                    const SizedBox(height: 24),
                    _buildAddressFields(),
                    const SizedBox(height: 24),
                    _buildPasswordFields(),
                    const SizedBox(height: 32),
                    _buildSignupButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
        _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '이메일',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansKR',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          validator: _validateEmail,
          onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
          decoration: InputDecoration(
            hintText: '(예시) abcd123@abcd.com',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontFamily: 'NotoSansKR',
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _isEmailChecking
                    ? Colors.grey[300]!
                    : _isEmailAvailable
                        ? Colors.grey[300]!
                        : Colors.red,
              ),
            ),
            suffixIcon: _isEmailChecking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : _emailController.text.isNotEmpty && _isValidEmail(_emailController.text)
                    ? Icon(
                        _isEmailAvailable ? Icons.check_circle : Icons.error,
                        color: _isEmailAvailable ? Colors.green : Colors.red,
                      )
                    : null,
            errorStyle: const TextStyle(
              color: Colors.red,
              fontFamily: 'NotoSansKR',
            ),
          ),
        ),
        if (!_isEmailAvailable && !_isEmailChecking)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '이미 사용 중인 이메일입니다.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontFamily: 'NotoSansKR',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '성별',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansKR',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => isMale = true),
                style: ElevatedButton.styleFrom(
                  primary: isMale ? const Color(0xFF4A55E7) : Colors.white,
                  side: BorderSide(color: isMale ? Colors.transparent : Colors.grey[300]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '남성',
                  style: TextStyle(
                    color: isMale ? Colors.white : Colors.black,
                    fontFamily: 'NotoSansKR',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => isMale = false),
                style: ElevatedButton.styleFrom(
                  primary: !isMale ? const Color(0xFF4A55E7) : Colors.white,
                  side: BorderSide(color: !isMale ? Colors.transparent : Colors.grey[300]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '여성',
                  style: TextStyle(
                    color: !isMale ? Colors.white : Colors.black,
                    fontFamily: 'NotoSansKR',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBirthDateSelection() {
    final days = _getDaysInMonth(selectedYear, selectedMonth);
    if (selectedDay != null && !days.contains(selectedDay)) {
      selectedDay = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '생년월일',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansKR',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                selectedYear ?? '년도',
                List.generate(100, (index) => (DateTime.now().year - index).toString()),
                (value) {
                  setState(() {
                    selectedYear = value;
                    _validateForm();
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                selectedMonth ?? '월',
                List.generate(12, (index) => (index + 1).toString().padLeft(2, '0')),
                (value) {
                  setState(() {
                    selectedMonth = value;
                    _validateForm();
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                selectedDay ?? '일',
                days,
                (value) {
                  setState(() {
                    selectedDay = value;
                    _validateForm();
                  });
                },
              ),
            ),
          ],
        ),
        if (!_isValidDate() && selectedYear != null && selectedMonth != null && selectedDay != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '올바른 생년월일을 선택해주세요.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontFamily: 'NotoSansKR',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdown(String value, List<String> items, Function(String) onChanged) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: items.contains(value) ? value : null,
        hint: Text(
          value,
          style: TextStyle(
            color: Colors.grey[600],
            fontFamily: 'NotoSansKR',
          ),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: const TextStyle(fontFamily: 'NotoSansKR'),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
        isExpanded: true,
        underline: const SizedBox(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  Widget _buildAddressFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주소',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansKR',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _addressController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: '주소 검색을 눌러주세요',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontFamily: 'NotoSansKR',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _searchAddress,
              style: ElevatedButton.styleFrom(
                primary: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '조회',
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'NotoSansKR',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _detailAddressController,
          focusNode: _detailAddressFocusNode,
          enabled: _isDetailAddressEnabled,
          decoration: InputDecoration(
            hintText: '상세 주소',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontFamily: 'NotoSansKR',
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          '비밀번호',
          _passwordController,
          '(예시) abcd123',
          validator: _validatePassword,
          obscureText: true,
          focusNode: _passwordFocusNode,
          onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
        ),
        const SizedBox(height: 16),
        _buildInputField(
          '비밀번호 확인',
          _confirmPasswordController,
          '(예시) abcd123',
          validator: _validateConfirmPassword,
          obscureText: true,
          focusNode: _confirmPasswordFocusNode,
        ),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String hint, {
    String? Function(String?)? validator,
    bool obscureText = false,
    FocusNode? focusNode,
    void Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansKR',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          focusNode: focusNode,
          onFieldSubmitted: onFieldSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontFamily: 'NotoSansKR',
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            errorStyle: const TextStyle(
              color: Colors.red,
              fontFamily: 'NotoSansKR',
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontFamily: 'NotoSansKR',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_isFormValid && !_isLoading) ? _handleSignup : null,
            style: ElevatedButton.styleFrom(
              primary: const Color(0xFF4A55E7),
              onPrimary: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    '가입하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'NotoSansKR',
                    ),
                  ),
          ),
        ),
      ],
    );
  }
} 