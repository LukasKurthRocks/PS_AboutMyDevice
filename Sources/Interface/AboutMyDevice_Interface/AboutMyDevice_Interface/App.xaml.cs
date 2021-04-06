using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Media;
using ControlzEx.Theming;
using MahApps.Metro;
using MahApps.Metro.Theming;

namespace AboutMyDevice_Interface {
    /// <summary>
    /// Interaction logic for App.xaml
    /// </summary>
    public partial class App : Application {
        protected override void OnStartup(StartupEventArgs e) {
            // Add custom theme resource dictionaries
            ThemeManager.Current.AddLibraryTheme(new LibraryTheme(
                                                     new Uri("pack://application:,,,/AboutMyDevice_Interface;component/CustomAccents/Light.Accent1.xaml"),
                                                     MahAppsLibraryThemeProvider.DefaultInstance));
            ThemeManager.Current.AddLibraryTheme(new LibraryTheme(
                                                     new Uri("pack://application:,,,/AboutMyDevice_Interface;component/CustomAccents/Dark.Accent1.xaml"),
                                                     MahAppsLibraryThemeProvider.DefaultInstance));
            ThemeManager.Current.AddLibraryTheme(new LibraryTheme(
                                                     new Uri("pack://application:,,,/AboutMyDevice_Interface;component/CustomAccents/Light.Accent2.xaml"),
                                                     MahAppsLibraryThemeProvider.DefaultInstance));
            ThemeManager.Current.AddLibraryTheme(new LibraryTheme(
                                                     new Uri("pack://application:,,,/AboutMyDevice_Interface;component/CustomAccents/Dark.Accent2.xaml"),
                                                     MahAppsLibraryThemeProvider.DefaultInstance));

            base.OnStartup(e);

            ThemeManager.Current.ThemeSyncMode = ThemeSyncMode.SyncWithAppMode;
            //ThemeManager.Current.SyncTheme();
            ThemeManager.Current.SyncTheme(ThemeSyncMode.SyncWithAppMode);

            // Create runtime themes
            ThemeManager.Current.AddTheme(new Theme("CustomDarkRed", "CustomDarkRed", "Dark", "Red", Colors.DarkRed, Brushes.DarkRed, true, false));
            ThemeManager.Current.AddTheme(new Theme("CustomLightRed", "CustomLightRed", "Light", "Red", Colors.DarkRed, Brushes.DarkRed, true, false));

            ThemeManager.Current.AddTheme(RuntimeThemeGenerator.Current.GenerateRuntimeTheme("Dark", Colors.Red));
            ThemeManager.Current.AddTheme(RuntimeThemeGenerator.Current.GenerateRuntimeTheme("Light", Colors.Red));

            ThemeManager.Current.AddTheme(RuntimeThemeGenerator.Current.GenerateRuntimeTheme("Dark", Colors.GreenYellow));
            ThemeManager.Current.AddTheme(RuntimeThemeGenerator.Current.GenerateRuntimeTheme("Light", Colors.GreenYellow));

            ThemeManager.Current.AddTheme(RuntimeThemeGenerator.Current.GenerateRuntimeTheme("Dark", Colors.Indigo));
            ThemeManager.Current.ChangeTheme(this, ThemeManager.Current.AddTheme(RuntimeThemeGenerator.Current.GenerateRuntimeTheme("Light", Colors.Indigo)));

            ThemeManager.Current.ChangeTheme(this, "Light.Red");
        }
    }
}
