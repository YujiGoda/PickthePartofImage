//
//  ViewController.swift
//  PickthePartofImage
//
//  Created by 合田佑司 on 2017/05/06.
//  Copyright © 2017年 YujiGoda. All rights reserved.
//

import UIKit


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var navigationBarOutlet: UINavigationBar!
    @IBOutlet weak var imageViewOutlet: UIImageView!
    @IBOutlet weak var saveBarButtonOutlet: UIBarButtonItem!
    @IBOutlet weak var returnOrignalButtonOutlet: UIButton!
    
    //赤枠の座標
    var pointList = Array<CGPoint>()
    //円の半径
    let radius : CGFloat = 8
    //赤枠の線の太さ
    let lineWidth : CGFloat = 2.0
    //赤枠用のImageView
    var redFrameView : UIImageView?
    //赤枠表示有無フラグ
    var flgRedFrame : Bool = false
    //元画像保持用
    var orignalImage : UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //初回実行時imageViewにまだデータがない場合、barの保存ボタンを無効化
        saveBarButtonOutlet.isEnabled = false
        //初回実行時imageViewにまだデータがない場合、barの写真を戻すボタンを無効化
        returnOrignalButtonOutlet.isHidden = true
        if let font = fontPropary {
            saveBarButtonOutlet.setTitleTextAttributes([NSFontAttributeName: font, NSForegroundColorAttributeName: backgroundColor], for: .normal)
        }
        self.view.backgroundColor = backgroundColor
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesBegin")
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if flgRedFrame {
            let touchEvent = touches.first
            
            let prePx = touchEvent?.previousLocation(in: self.imageViewOutlet).x
            let prePy = touchEvent?.previousLocation(in: self.imageViewOutlet).y
            
            if let flgInt = checktouchLocation(touchX: prePx!, touchY: prePy!) {
                let newPx = touchEvent?.location(in: self.imageViewOutlet).x
                let newPy = touchEvent?.location(in: self.imageViewOutlet).y
                
                pointList[flgInt].x = newPx!
                pointList[flgInt].y = newPy!
                
                let redFrameImage = describeRedFrame()
                redFrameView?.removeFromSuperview()
                redFrameView = UIImageView(image: redFrameImage)
                imageViewOutlet.addSubview(redFrameView!)
            }
        } else {
            return
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touch end")
    }
    
    //ライブラリから写真取得
    @IBAction func getLibraryImage(_ sender: UIBarButtonItem) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
            let picker = UIImagePickerController()
            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            picker.allowsEditing = true
            picker.delegate = self
            present(picker, animated: true, completion: nil)
        }
    }
    
    //赤枠の表示
    @IBAction func showRedFrame(_ sender: UIButton) {
        if flgRedFrame {
            redFrameView?.removeFromSuperview()
        }
        //初回赤枠の座標取得
        pointList = firstRedFramePoint()
        //赤枠を描写したUIImageデータを作成
        let redFrameImage = describeRedFrame()
        
        //UIImageデータをImageViewに
        redFrameView = UIImageView(image: redFrameImage)
        imageViewOutlet.addSubview(redFrameView!)
        flgRedFrame = true
    }
    
    //射影変換により画像の一部を切り取り
    @IBAction func pickPartofImage(_ sender: UIButton) {
        
        var realPointList : Array<CGPoint> = changePointList()
        
        if let inputImage = imageViewOutlet.image {
            var homoPara = UnsafeMutablePointer<Double>.allocate(capacity: 8)
            for i in 0...3 {
                homoPara[2*i] = Double(realPointList[i].x)
                homoPara[2*i+1] = Double(realPointList[i].y)
            }
            
            let opencv = OpenCVFunc()
            let homoImage = opencv.homographyImage(inputImage, homopara: homoPara)
            imageViewOutlet.image = homoImage
            
            redFrameView?.removeFromSuperview()
        }
    }
    
    @IBAction func returnOrignalImage(_ sender: UIButton) {
        if let image = orignalImage {
            imageViewOutlet.image = image
        }
    }
    
    @IBAction func saveImage(_ sender: UIBarButtonItem) {
        if let image = imageViewOutlet.image {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_image:didFinishSaveWithError:contextInfo:)), nil)
        }
    }
    
    func image(_image : UIImage, didFinishSaveWithError error: NSError?, contextInfo: UnsafeMutableRawPointer) {
        print(error?.code ?? 0)
    }
    
    //Libraryから写真を取得した際の挙動
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var newImage : UIImage
        
        if let possibleImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            newImage = possibleImage
        } else if let possibleImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            newImage = possibleImage
        } else {
            return
        }
        
        dismiss(animated: true, completion: nil)
        imageViewOutlet.image = newImage
        //元画像を文字
        orignalImage = newImage
        //写真を戻すボタンを有効化
        returnOrignalButtonOutlet.isHidden = false
        //保存ボタンを有効化
        saveBarButtonOutlet.isEnabled = true
        if let font = fontPropary {
            saveBarButtonOutlet.setTitleTextAttributes([NSFontAttributeName: font, NSForegroundColorAttributeName: barColor], for: .normal)
        }
        //赤枠があれば削除
        redFrameView?.removeFromSuperview()
        flgRedFrame = false
    }
    
    //赤枠の初期座標取得
    func firstRedFramePoint() -> Array<CGPoint> {
        var points = Array<CGPoint>()
        points.append(CGPoint(x: imageViewOutlet.bounds.width / 3.0, y: imageViewOutlet.bounds.height / 3.0))
        points.append(CGPoint(x: imageViewOutlet.bounds.width * 2.0 / 3.0, y: imageViewOutlet.bounds.height / 3.0))
        points.append(CGPoint(x: imageViewOutlet.bounds.width * 2.0 / 3.0, y: imageViewOutlet.bounds.height * 2.0 / 3.0))
        points.append(CGPoint(x: imageViewOutlet.bounds.width / 3.0, y: imageViewOutlet.bounds.height * 2.0 / 3.0))
        
        return points
    }
    
    //赤枠の描写
    func describeRedFrame() -> UIImage {
        //赤枠の座標を複製(編集用)
        var points : Array<CGPoint> = pointList
        let size = imageViewOutlet.bounds.size
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        
        let drawPath = UIBezierPath()
        //赤枠のためカラーにredを指定
        UIColor.red.setStroke()
        //赤枠の太さは1.0
        drawPath.lineWidth = lineWidth
        //赤枠と座標の点の重なり部分を塗りつぶし
        drawPath.usesEvenOddFillRule = false
        
        drawPath.move(to: points[0])
        points.append(points[0])
        points.removeFirst()
        
        for pt in points {
            drawPath.addLine(to: pt)
        }
        
        //4つの頂点座標に円を表示
        describeCircle(drawPath: drawPath)
        
        //図形描写
        drawPath.stroke()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    //4つの頂点に円を描写するための設定
    func describeCircle(drawPath : UIBezierPath) {
        //円の塗りつぶしはred
        UIColor.red.setFill()
        for pt in pointList {
            let circlePath = UIBezierPath(arcCenter: pt, radius: radius, startAngle: 0.0, endAngle: CGFloat(2 * M_PI), clockwise: true)
            circlePath.fill()
            drawPath.append(circlePath)
        }
    }
    
    //タップされた箇所が円の中かどうか判断
    //もし円内であればその円の番号を返す
    //もし円外であればnilを返す
    func checktouchLocation(touchX : CGFloat, touchY : CGFloat) -> Int? {
        var flgInt : Int?
        
        for i in 0...3{
            let diffPx = fabs(touchX - pointList[i].x) as CGFloat
            let diffPy = fabs(touchY - pointList[i].y) as CGFloat
            //タップされた座標とpointList[i]の中心座標との距離
            let lenght = sqrt((diffPx * diffPx + diffPy * diffPy)) as CGFloat
            
            //もしタップされた座標と円の中心座標との距離が円の半径radiusより短ければ、タップされた箇所は円の中と判断
            //どの円かをflgIntに格納しループを抜ける
            if radius >= lenght {
                flgInt = i
                break
            }
        }
        
        return flgInt
    }
    
    func changePointList() -> Array<CGPoint> {
        var changePointList = Array<CGPoint>()
        let changeRate = imageViewOutlet.bounds.width / (imageViewOutlet.image?.size.width)!
        let changeImageWidth = (imageViewOutlet.image?.size.width)! * changeRate
        let changeImageHeight = (imageViewOutlet.image?.size.height)! * changeRate
        
        for i in 0...3 {
            var changePoint = CGPoint()
            if imageViewOutlet.bounds.size.width == changeImageWidth {
                changePoint.x = pointList[i].x / changeRate
            } else {
                changePoint.x = ( pointList[i].x - ( imageViewOutlet.bounds.size.width - changeImageWidth ) / 2 ) / changeRate
            }
            if imageViewOutlet.bounds.size.height == changeImageHeight {
                changePoint.y = pointList[i].y / changeRate
            } else {
                changePoint.y = ( pointList[i].y - ( imageViewOutlet.bounds.size.height - changeImageHeight ) / 2 ) / changeRate
            }
            changePointList.append(changePoint)
        }
        
        return changePointList
    }

}

