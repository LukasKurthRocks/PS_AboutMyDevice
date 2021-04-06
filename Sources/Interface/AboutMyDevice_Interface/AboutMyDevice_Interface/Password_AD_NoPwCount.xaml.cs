using MahApps.Metro.Controls;
using System;
using System.Collections.Generic;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;

namespace AboutMyDevice_Interface {
    /// <summary>
    /// Interaktionslogik für Password_AD_NoPwCount.xaml
    /// </summary>
    public partial class Password_AD_NoPwCount : MetroWindow {
        public Password_AD_NoPwCount() {
            InitializeComponent();
        }

        /*
        private PasswordWindowsStartTest01 _parentWindow;

        public Password_AD_NoPwCount(PasswordWindowsStartTest01 _wind) {
            InitializeComponent();

            _parentWindow = _wind;
        }
        */

        private MetroWindow accentThemeTestWindow;

        private void ChangeAppStyleButtonClick(object sender, RoutedEventArgs e) {
            if (accentThemeTestWindow != null) {
                accentThemeTestWindow.Activate();
                return;
            }

            accentThemeTestWindow = new AccentStyleWindow();
            accentThemeTestWindow.Owner = this;
            accentThemeTestWindow.Closed += (o, args) => accentThemeTestWindow = null;
            accentThemeTestWindow.Left = this.Left + this.ActualWidth / 2.0;
            accentThemeTestWindow.Top = this.Top + this.ActualHeight / 2.0;
            accentThemeTestWindow.Show();
        }

        private void Click_Authenticate(object sender, RoutedEventArgs e) {
            /*
             * I will not implement this in C#, this ist just for testing reason.
             * The rest will be done in PowerShell scripting stuff...
             * 
             * Anyone can implement this with the following information:
             * - Typed_User.Text for the user input
             * - Typed_PWD.Text for the password input
             * 
             * Password and ecnryption stuff is not what this C# script was written for.
             * This class (PasswordWindow) has to return a value to check if verification via AD has been successful.
             * https://stackoverflow.com/questions/3468433/return-an-object-from-a-popup-window
             * 
             * Make sure to use ShowDialog() for true/false
             */
            //return true;
            //_parentWindow.resultValue = "321321"; // return a value with coded parent class!

            var authenticated = true;
            Window.GetWindow(this).DialogResult = authenticated;
            Window.GetWindow(this).Close();
        }
    }
}