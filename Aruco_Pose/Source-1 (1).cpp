#include <iostream> 
#include <opencv2/opencv.hpp> 
#include <opencv2/aruco.hpp>
#include <windows.h> // For Sleep() 
const float markerLength = 2.0;
std::vector<double> calcVec(cv::Vec3d rvec) 
{ cv::Mat R; 
  cv::Rodrigues(rvec, R); // convert to rotation matrix
  
  double ax, ay, az; 
  ay = atan2(R.at<double>(2, 0), pow(pow(R.at<double>(0, 0), 2) + pow(R.at<double>(1, 0), 2), 0.5)); 
  double cy = cos(ay); if (abs(cy) < 1e-9) 
  
  if (abs(cy) < 1e-9) 
  { // Degenerate solution. 
	  az = 0.0; 
	  ax = atan2(R.at<double>(0, 1), R.at<double>(1, 1)); 
	  if (ay < 0) ax = ax; 
  } 
  else 
  { 
	  az = atan2(R.at<double>(1, 0) / cy, R.at<double>(0, 0) / cy); 
	  ax = atan2(R.at<double>(2, 1) / cy, R.at<double>(2, 2) / cy); 
  }

	std::vector<double> result; 
	result.push_back(ax); 
	result.push_back(ay); 
	result.push_back(az); 
	return result;
}

int main(int argc, char* argv[]) 
{
	printf("This program detects ArUco markers.\n"); 
	printf("Hit the ESC key to quit.\n");
	// Camera intrinsic matrix (fill in your actual values here). 
	double K_[3][3] = { { 675, 0, 320 }, { 0, 675, 240 }, { 0, 0, 1 } }; 
	cv::Mat K = cv::Mat(3, 3, CV_64F, K_).clone();
	// Distortion coeffs (fill in your actual values here).
	double dist_[] = { 0, 0, 0, 0, 0 }; 
	cv::Mat distCoeffs = cv::Mat(5, 1, CV_64F, dist_).clone(); 
	//cv::Mat distCoeffs = cv::Mat::zeros(5, 1, CV_64F); 
	// distortion coeffs
	//cv::VideoCapture cap(0); for webcam
	// open the camera 
	cv::VideoCapture cap("hw4.avi"); 
	// open the video file
	if (!cap.isOpened()) 
	{ 
		// check if we succeeded 
		printf("error can't open the camera or video; hit any key to quit\n"); 
		system("PAUSE"); 
		return EXIT_FAILURE; 
	} 
	// Let's just see what the image size is from this camera or file. 
	double WIDTH = cap.get(CV_CAP_PROP_FRAME_WIDTH); 
	double HEIGHT = cap.get(CV_CAP_PROP_FRAME_HEIGHT); 
	printf("Image width=%f, height=%f\n", WIDTH, HEIGHT);

	// Allocate image. 
	cv::Mat image; 
	cv::Ptr<cv::aruco::Dictionary> dictionary = cv::aruco::getPredefinedDictionary(cv::aruco::DICT_4X4_100); 
	cv::Ptr<cv::aruco::DetectorParameters> detectorParams = cv::aruco::DetectorParameters::create();

	// Write a video in OpenCV from HW4 question.
	const cv::String fnameOut("HW_4_video.avi"); 
	cv::VideoWriter outputVideo(fnameOut, cv::VideoWriter::fourcc('D', 'I', 'V', 'X'), 15.0, cv::Size((int)WIDTH, (int)HEIGHT), true); 
    
	// Run an infinite loop until user hits the ESC key. 
	while (1) 
	{ cap >> image; 
	// get image from camera 
	if (image.empty()) 
		break;
	//In "Detecting Square Markers using OpenCV Lecture." slide 
    #if 1 
	std::vector< int > markerIds; 
	std::vector< std::vector<cv::Point2f> > markerCorners, rejectedCandidates; 
	cv::aruco::detectMarkers( image, dictionary, markerCorners, markerIds, detectorParams, rejectedCandidates);

	if (markerIds.size() > 0) 
	{ 
		// Draw all detected markers. 
		cv::aruco::drawDetectedMarkers(image, markerCorners, markerIds);
		std::vector< cv::Vec3d > rvecs, tvecs; 
		cv::aruco::estimatePoseSingleMarkers(markerCorners, markerLength, K, distCoeffs, rvecs, tvecs);


	// Display pose for the detected marker with id=0. 
		for (unsigned int i = 0; i < markerIds.size(); i++) 
		{ 
			if (markerIds[i] == 0 || markerIds[i] == 1) 
			{ 
				cv::Vec3d r = rvecs[i];
				cv::Vec3d t = tvecs[i];
	            // Draw coordinate axes. 
		        cv::aruco::drawAxis(image, K, distCoeffs, r, t, 0.5*markerLength);
			    double x = 0, y = 0, z = 0; 
				if (markerIds[i] == 0) 
				{
				
					x = 2.5; y = 2.0; 
					z = 1.0;
			    }
				else if (markerIds[i] == 1) 
				{
					x = 2.5; 
					y = 2.0; 
					z = 5.0;
				}
       
				std::vector<cv::Point3d> pointsInterest; 
				pointsInterest.push_back(cv::Point3d(x, y,z));
				std::vector<cv::Point2d> p; 
				cv::projectPoints(pointsInterest, rvecs[i], tvecs[i], K, distCoeffs, p);
				cv::circle(image, p[0], 20, cv::Scalar(0, 255, 255), 2);
			 }
		}
	}
    #endif
		cv::imshow("Image", image); 
		outputVideo << image;
	   // Wait for x ms (0 means wait until a keypress). 
	   // Returns 1 if no key is hit. 
		char key = cv::waitKey(1); 
		if (key == 27) break; 
// ESC is ascii 27
	}
	return EXIT_SUCCESS;
}


																						


