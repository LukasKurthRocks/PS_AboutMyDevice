using MahApps.Metro.Controls;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
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
    /// Interaktionslogik für AdminPanel.xaml
    /// </summary>
    public partial class AdminPanel : MetroWindow {
        public AdminPanel() {
            InitializeComponent();

            SetStatusBar("", "");

            // set via PowerShell
            var oc = new ObservableCollection<string>();
            oc.Add("19041");
            dgrUpgradeHistory.ItemsSource = oc;
        }

        private void Click_LaunchGitHubSite(object sender, RoutedEventArgs e) {

        }

        private void Click_OpenAdminPanel(object sender, RoutedEventArgs e) {

        }

        private void Click_ChangeAppStyleButtonClick(object sender, RoutedEventArgs e) {

        }

        private void ToggleSwitch_Toggled(object sender, RoutedEventArgs e) {

        }

        private void SetStatusBar(string infoText, string messageText, int value = 0, bool isIndeterminate = false, bool isActive = false) {
            lblInfoText.Text = infoText;
            lblMessageText.Text = messageText;
            mpbProgress.Value = value;
            mpbProgress.IsIndeterminate = isIndeterminate;

            mpbProgress.IsEnabled = isActive;
            if (isActive)
                mpbProgress.Visibility = Visibility.Visible;
            else
                mpbProgress.Visibility = Visibility.Hidden;
        }
    }
}
