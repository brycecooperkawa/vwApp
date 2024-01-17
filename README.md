# Volkswagen Shopping App with Augmented Reality



## An iOS mobile application that uses augmented reality to display Volkswagen cars in the real world. 

In this mobile app, users can select individual Volkswagen models to explore their interiors or navigate to official Volkswagen webpages to see vehicle information. The 3D models also have customizable colors and an arrangement of accessories for personalization, with the option to save a customized car for later viewing. Our app displays up to two different cars in the real world using AR, beginning with a dynamic positioning phase that ends when the user "places" the car down. Integrated photo and video capture, followed by the share functionality, gives users the chance to easily share their experience with family and friends via iMessage, Mail, and other apps.



* Vehicle Selection
* Augmented Reality Interior Display
* Website Navigation
* Customization Options
* Augmented Reality Exterior Display
* Capture Photo/Video
* Share Photo



## Table of Contents

- [Installation](#Installation)
- [Known Bugs](#Bugs)
- [Usage](#Usage)
- [Authors and acknowledgments](#Acknowledgments)



## Installation
Note: To install and run the application this project must first be opened in Xcode on a macOS device and subsequently installed and run in Developer mode on an iOS Device.
Note: This project must be run on iOS version 14.0 or later
Desktop Prep
1. Download the latest version of Xcode
2. Clone this project into a local directory and open the project in XCode 
3. Configure Code Signing:
In Xcode, select the project in the Project Navigator.
Under the "Signing & Capabilities" tab, configure the code signing settings. You might need to select a team and provide a bundle identifier.

iOS Device Prep
1. Ensure that your iOS device has been installed with at least iOS version 14.0
2. Sign in with your AppleID and enable Developer Mode
3. Configure Code Signing:
In Xcode, select the project in the Project Navigator.
Under the "Signing & Capabilities" tab, configure the code signing settings. You might need to select a team and provide a bundle identifier.
4. Go to the Settings app, and navigate to Privacy & Security > Developer Mode.
5. Enable the toggle.
6. You will receive a prompt from iOS to restart your device. Press Restart.
7. Once your device is in Developer Mode, run the project from XCode with your device connected and selected as the run destination
8. Once the app is installed you'll be notified that the app is untrusted
9. To trust the app and run it on your device, navigate to VPN & Device Management > select the tag for the developer app > select 'Trust "Apple Development:  youremail@email.com"'
10. Your app should now be running refer to the Usage section for instructions on how to best use the app



## Known Bugs
1. Attempting to display two instances of the same vehicle model but with different colors will force both vehicles to take on only one color. For example: selecting a saved customized instance of Car1 that is yellow, then selecting an instance of Car1 that is red, may result in both cars appearing red when placed in AR. This error does not occur when placing different vehicle models, such as a yellow Car1 and an orange Car2.
2. In situations where the app displays the download bar (such as when new models have been uploaded), if the user logs in and then returns back to the login screen, that download bar remains.
3. On rare occasion, the app may crash when an AR raycast fails. This may be a race condition stemming from the asynchronous nature of raycast.



## Usage

1. Open the app and if you are a first time user create a new account by pressing the create account button, fill in the required credentials and login.

2. Once you are logged in select a car to enable all of the button options, while a car is selected you have the option to select "Interior", "Car Info", "Customize", and "Display".

    - 2a. When Interior is selected the app transitions to the AR interior view of the chosen vehicle. The user can switch their car position by pressing the "Next Seat" button, also emit horn sound by touching the wheel while being in the drivers seat.

    - 2b. When Car Info is selected the app transitions to the official Volkswagen website for the chosen vehicle.

    - 2c. When Customize is selected the app transitions to the Customization view. You will be able to change the color of the chosen vehicle and add accessories. Once you have your personalized vehicle you can either press the "Save" button for later viewing or "Confirm" button to display the vehicle in an AR view.

    - 2d. When "Display" is selected the app transitions to the AR view to display the selected vehicle. To display mulitple cars in AR view select multiple cars and press "Display".

3. When you are in the AR view, find an open space to display the Volkswagen vehicle. To change the size of the vehicle you can choose from the options "Small", "Medium", and "Actual". When you are satisfied with the size and placement of the vehicle press the "Add" button to place the vehicle.

4. Once the car is placed you have the option to capture a photo/video. To capture a photo tap the camera icon and to capture a video tap the video recorder icon.

    -4a. When you select the photo capture, the "Capture" button will be displayed and when "Capture" is pressed it will capture a photo. Once a photo is captured you will have the option to save the photo by tapping the download icon button or share the photo via IMessage, Mail, and etc. by pressing the upload icon. If you are not satisfied with the photo that you captured you can press the "Retake" button to recapture the photo.




## Authors and Acknowledgments

### Authors

MSU Capstone Team Volkswagen

- **Bryce Cooperkawa**
- **Nahom Ghebredngl**
- **Rikito Takai**
- **Swathi Thippireddy**
- **Richard Zhou**

### Acknowledgments

Volkswagen Sponsor

- **Hassan Elnajjar**
- **Igor Efremov**
- **Eugene Pavlov**