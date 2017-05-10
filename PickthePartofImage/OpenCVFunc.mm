//
//  OpenCVFunc.m
//  PickthePartofImage
//
//  Created by 合田佑司 on 2017/05/06.
//  Copyright © 2017年 YujiGoda. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <Foundation/Foundation.h>
#import "PickthePartofImage-Bridging-Header.h"

@implementation OpenCVFunc : NSObject 

-(UIImage *) homographyImage:(UIImage *)image homopara:(double *)homopara
{
    cv::Mat inputMat;
    UIImageToMat(image, inputMat);
    float cols, rows;
    
    cv::Mat outputMat(inputMat.size(), inputMat.type());
    
    
    const cv::Point2f src_pt[] = {
        cv::Point2f(homopara[0], homopara[1]),
        cv::Point2f(homopara[2], homopara[3]),
        cv::Point2f(homopara[4], homopara[5]),
        cv::Point2f(homopara[6], homopara[7]),
    };
    
    cols = ( homopara[2] - homopara[0] + homopara[4] - homopara[6] ) / 2.0 ;
    rows = ( homopara[7] - homopara[1] + homopara[5] - homopara[3] ) / 2.0;
    
    const cv::Point2f dst_pt[] = {
        cv::Point2f(0.0, 0.0),
        cv::Point2f(cols, 0.0),
        cv::Point2f(cols, rows),
        cv::Point2f(0.0, rows),
    };
    
    const cv::Mat homoMatrix = cv::getPerspectiveTransform(src_pt, dst_pt);
    
    cv::warpPerspective(inputMat, outputMat, homoMatrix, cv::Size(cols, rows));
    
    return MatToUIImage(outputMat);
}


@end


