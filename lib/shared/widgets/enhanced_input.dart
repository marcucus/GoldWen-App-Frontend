import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/accessibility_service.dart';
import '../../core/theme/app_theme.dart';

/// Enhanced text field with sophisticated focus animations and validation feedback
class EnhancedTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final Function()? onTap;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final bool enableCounter;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool enableHapticFeedback;

  const EnhancedTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.enableCounter = false,
    this.inputFormatters,
    this.validator,
    this.enableHapticFeedback = true,
  });

  @override
  State<EnhancedTextField> createState() => _EnhancedTextFieldState();
}

class _EnhancedTextFieldState extends State<EnhancedTextField>
    with TickerProviderStateMixin {
  late AnimationController _focusController;
  late AnimationController _errorController;
  late AnimationController _successController;
  
  late Animation<double> _focusAnimation;
  late Animation<double> _errorAnimation;
  late Animation<double> _successAnimation;
  late Animation<Color?> _borderColorAnimation;

  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _hasError = false;
  bool _hasSuccess = false;

  @override
  void initState() {
    super.initState();
    
    final accessibilityService = context.read<AccessibilityService>();
    
    _focusController = AnimationController(
      duration: accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 200)
      ),
      vsync: this,
    );
    
    _errorController = AnimationController(
      duration: accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 300)
      ),
      vsync: this,
    );
    
    _successController = AnimationController(
      duration: accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 300)
      ),
      vsync: this,
    );

    _focusAnimation = CurvedAnimation(
      parent: _focusController,
      curve: Curves.easeInOut,
    );

    _errorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _errorController,
      curve: Curves.elasticOut,
    ));

    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.easeOut,
    ));

    _borderColorAnimation = ColorTween(
      begin: AppColors.dividerLight,
      end: AppColors.primaryGold,
    ).animate(_focusAnimation);

    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(EnhancedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final bool hadError = _hasError;
    _hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    
    if (!hadError && _hasError) {
      _showError();
    } else if (hadError && !_hasError) {
      _hideError();
    }

    // Check for success (valid input after error)
    if (hadError && !_hasError && widget.controller?.text.isNotEmpty == true) {
      _showSuccess();
    }
  }

  @override
  void dispose() {
    _focusController.dispose();
    _errorController.dispose();
    _successController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() => _isFocused = _focusNode.hasFocus);
    
    final accessibilityService = context.read<AccessibilityService>();
    if (!accessibilityService.reducedMotion) {
      if (_isFocused) {
        _focusController.forward();
      } else {
        _focusController.reverse();
      }
    }

    if (_isFocused && widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
  }

  void _showError() {
    final accessibilityService = context.read<AccessibilityService>();
    if (!accessibilityService.reducedMotion) {
      _errorController.forward();
    }
    
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }
  }

  void _hideError() {
    final accessibilityService = context.read<AccessibilityService>();
    if (!accessibilityService.reducedMotion) {
      _errorController.reverse();
    }
  }

  void _showSuccess() {
    final accessibilityService = context.read<AccessibilityService>();
    if (!accessibilityService.reducedMotion) {
      _successController.forward().then((_) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _successController.reverse();
          }
        });
      });
    }
    
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessibilityService = context.watch<AccessibilityService>();
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        _focusAnimation,
        _errorAnimation,
        _successAnimation,
      ]),
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main TextField Container
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: _isFocused && !accessibilityService.reducedMotion
                    ? [
                        BoxShadow(
                          color: AppColors.primaryGold.withOpacity(0.2),
                          blurRadius: 8.0 * _focusAnimation.value,
                          spreadRadius: 1.0 * _focusAnimation.value,
                        ),
                      ]
                    : null,
              ),
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                readOnly: widget.readOnly,
                maxLines: widget.maxLines,
                maxLength: widget.maxLength,
                inputFormatters: widget.inputFormatters,
                validator: widget.validator,
                onChanged: widget.onChanged,
                onFieldSubmitted: widget.onSubmitted,
                onTap: widget.onTap,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  labelText: widget.labelText,
                  hintText: widget.hintText,
                  helperText: widget.helperText,
                  errorText: widget.errorText,
                  counterText: widget.enableCounter ? null : '',
                  
                  // Prefix Icon with animation
                  prefixIcon: widget.prefixIcon != null
                      ? AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            widget.prefixIcon,
                            color: _isFocused 
                                ? AppColors.primaryGold
                                : AppColors.textSecondary,
                          ),
                        )
                      : null,
                  
                  // Suffix Icon with success/error states
                  suffixIcon: _buildSuffixIcon(),
                  
                  // Enhanced border styling
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.dividerLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _hasError 
                          ? AppColors.errorRed.withOpacity(0.3)
                          : AppColors.dividerLight,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _hasError 
                          ? AppColors.errorRed
                          : _borderColorAnimation.value ?? AppColors.primaryGold,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.errorRed),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.errorRed,
                      width: 2,
                    ),
                  ),
                  
                  // Enhanced label styling
                  labelStyle: TextStyle(
                    color: _isFocused
                        ? AppColors.primaryGold
                        : AppColors.textSecondary,
                  ),
                  floatingLabelStyle: TextStyle(
                    color: _hasError
                        ? AppColors.errorRed
                        : AppColors.primaryGold,
                  ),
                ),
              ),
            ),
            
            // Enhanced Error/Helper Text
            if (widget.errorText != null || widget.helperText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: AnimatedBuilder(
                  animation: _errorAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        accessibilityService.reducedMotion 
                            ? 0 
                            : -5 * _errorAnimation.value,
                        0,
                      ),
                      child: Text(
                        widget.errorText ?? widget.helperText ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: widget.errorText != null
                              ? AppColors.errorRed
                              : AppColors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget? _buildSuffixIcon() {
    final accessibilityService = context.watch<AccessibilityService>();
    
    if (_hasSuccess && !accessibilityService.reducedMotion) {
      return AnimatedBuilder(
        animation: _successAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _successAnimation.value,
            child: const Icon(
              Icons.check_circle,
              color: AppColors.successGreen,
            ),
          );
        },
      );
    }
    
    if (_hasError && !accessibilityService.reducedMotion) {
      return AnimatedBuilder(
        animation: _errorAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _errorAnimation.value * 0.1,
            child: const Icon(
              Icons.error,
              color: AppColors.errorRed,
            ),
          );
        },
      );
    }
    
    if (widget.suffixIcon != null) {
      return GestureDetector(
        onTap: widget.onSuffixIconTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            widget.suffixIcon,
            color: _isFocused 
                ? AppColors.primaryGold
                : AppColors.textSecondary,
          ),
        ),
      );
    }
    
    return null;
  }
}

/// Enhanced search bar with smooth animations
class EnhancedSearchBar extends StatefulWidget {
  final String? hintText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final TextEditingController? controller;

  const EnhancedSearchBar({
    super.key,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.controller,
  });

  @override
  State<EnhancedSearchBar> createState() => _EnhancedSearchBarState();
}

class _EnhancedSearchBarState extends State<EnhancedSearchBar>
    with TickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    
    _controller = widget.controller ?? TextEditingController();
    
    final accessibilityService = context.read<AccessibilityService>();
    _expandController = AnimationController(
      duration: accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 300)
      ),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _expandController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      
      final accessibilityService = context.read<AccessibilityService>();
      if (!accessibilityService.reducedMotion) {
        if (hasText) {
          _expandController.forward();
        } else {
          _expandController.reverse();
        }
      }
    }
    
    widget.onChanged?.call(_controller.text);
  }

  void _onClear() {
    _controller.clear();
    HapticFeedback.lightImpact();
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        textInputAction: TextInputAction.search,
        onSubmitted: widget.onSubmitted,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Rechercher...',
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textSecondary,
          ),
          suffixIcon: AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _expandAnimation.value,
                child: _hasText
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: _onClear,
                      )
                    : const SizedBox(),
              );
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}