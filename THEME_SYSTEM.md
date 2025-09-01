# Theme System Documentation

## Overview

The GoldWen app implements a comprehensive theme system with Art Deco design inspired by the application's logo and branding. The system supports three theme modes:

- **Light Theme**: Art Deco golden style with warm colors
- **Dark Theme**: Art Deco dark style with elegant contrasts
- **System Theme**: Automatically follows the device's theme setting (default)

## Architecture

### ThemeProvider
The `ThemeProvider` class manages the application's theme state and persistence:

```dart
// Usage example
final themeProvider = Provider.of<ThemeProvider>(context);
themeProvider.setThemeMode(AppThemeMode.dark);
```

### AppTheme
The `AppTheme` class provides static methods for light and dark themes:

```dart
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
)
```

## Art Deco Design Elements

### Color Palette

#### Light Theme
- Primary Gold: `#D4AF37`
- Secondary Beige: `#F5F5DC`
- Accent Cream: `#FAF0E6`
- Text Dark: `#2C2C2C`

#### Dark Theme
- Primary Gold Dark: `#B8941F`
- Background Dark: `#1A1A1A`
- Background Dark Secondary: `#2D2D2D`
- Text Light: `#F5F5F5`

### Typography
- **Headlines**: Playfair Display (Serif) - Art Deco elegance
- **Body Text**: Lato (Sans-Serif) - Modern readability

### Components

#### AppLogo
Theme-aware logo component that automatically selects the appropriate logo:

```dart
AppLogo(
  width: 120,
  height: 120,
  useTransparentVersion: true, // For in-app display
)
```

#### ArtDecoCard
Custom card component with Art Deco styling:

```dart
ArtDecoCard(
  showGradient: true,
  onTap: () => {},
  child: YourContent(),
)
```

## Usage Guidelines

### Theme Selection UI
The theme selection is available in the user profile settings:
1. Open profile page
2. Tap settings icon
3. Select "Thème"
4. Choose from Light, Dark, or System

### For Developers

#### Using Theme Colors
Always use theme-aware colors from `AppColors`:

```dart
// Good
Container(
  color: themeProvider.isDarkMode 
    ? AppColors.backgroundDark 
    : AppColors.backgroundWhite,
)

// Better - using theme system
Container(
  color: Theme.of(context).scaffoldBackgroundColor,
)
```

#### Theme-Aware Components
Create components that respond to theme changes:

```dart
Consumer<ThemeProvider>(
  builder: (context, themeProvider, child) {
    return Container(
      color: themeProvider.isDarkMode 
        ? AppColors.primaryGoldDark 
        : AppColors.primaryGold,
      child: child,
    );
  },
)
```

## Logo Assets

The system automatically selects appropriate logos:
- `logo_light.png` - For light theme/backgrounds
- `logo_dark.png` - For dark theme/backgrounds
- `logo_sans_fond.png` - Transparent version for in-app use
- `logo_base.png` - Fallback logo

## Best Practices

1. **Consistency**: Always use the defined color palette
2. **Accessibility**: Ensure proper contrast ratios in both themes
3. **Performance**: Use `Consumer<ThemeProvider>` only when necessary
4. **Persistence**: Theme preferences are automatically saved
5. **System Integration**: Respect user's system theme preference by default

## Testing

Run the theme tests to ensure proper functionality:

```bash
flutter test test/theme_provider_test.dart
```

## Future Enhancements

- High contrast theme support
- Custom color themes
- Animation transitions between themes
- Theme-specific icons and illustrations