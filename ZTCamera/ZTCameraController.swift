//
//  ZTCameraController.swift
//  ZTKamera
//
//  Created by Tony.su on 2017/12/22.
//  Copyright © 2017年 Tony.su. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

protocol ZTCameraControllerDelegate {
    
    func deviceConfigurationFailed(withError error:NSError)
    func mediaCaptureFailed(withError error: NSError)
    func assetLibraryWriteFailed(withError error: NSError)
}


var ZTThumbnailCreatedNotification = "THThumbnailCreated"

class ZTCameraController: UIViewController {

    var delegate: ZTCameraControllerDelegate?
    private(set) var captureSession: AVCaptureSession?
    var cameraCount: UInt{
        //iOS10之前
        //        var devices = AVCaptureDevice.devices(for: .video)
        
        //获取可用视频设备
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
        let devices = discoverySession.devices
        return UInt(devices.count)
    }
    //手电筒
    var cameraHasTorch:Bool {
        get{
            if let activeCamera = self.activeCamera() {
                return activeCamera.hasTorch
            }else{
                return false
            }
        }
    }
    //闪光灯
    var cameraHasFlash:Bool {
        if let activeCamera = self.activeCamera() {
            return activeCamera.hasFlash
        }else{
            return false
        }
    }
    //聚焦
    var cameraSupportsTapToFocus: Bool {
        get {
            if let activeCamera = self.activeCamera() {
                return activeCamera.isFocusPointOfInterestSupported
            }else{
                return false
            }
            
        }
    }
    //曝光
    var cameraSupportsTapToExpose: Bool {
        get {
            if let activeCamera = self.activeCamera() {
                return activeCamera.isExposurePointOfInterestSupported
            }else{
                return false
            }
            
        }
    }
    //手电筒模式
    var torchMode: AVCaptureDevice.TorchMode = .off{
        didSet {
            
            if let device = self.activeCamera() {
                if device.isTorchModeSupported(torchMode){
                    do{
                        try device.lockForConfiguration()
                        device.torchMode = torchMode
                        device.unlockForConfiguration()
                    }catch let error as NSError {
                        self.delegate?.deviceConfigurationFailed(withError: error)
                    }
                }
            }
        }
    }
    var flashMode: AVCaptureDevice.FlashMode = .off   //闪光灯模式
    //视频队列
    private var videoQueue: DispatchQueue = {
        return DispatchQueue(label: "zt.videoQueue")
    }()
    private var activeVideoInput: AVCaptureDeviceInput?  //输入
    private var imageOutput: AVCapturePhotoOutput?
    private var movieOutPut: AVCaptureMovieFileOutput?
    private var outPutURL: NSURL?
    private var localIdentifier: String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &ZTThumbnailCreatedNotification {
            //获取device
            guard let device = object as? AVCaptureDevice else { return }
            //判断设备是否不再调整曝光等级,确认设备的exposureMode是否可以设置为.locked
            if !device.isAdjustingExposure && device.isExposureModeSupported(.locked) {
                //移除监听
                device.removeObserver(self, forKeyPath: "adjustingExposure", context: &ZTThumbnailCreatedNotification)
                
                //异步方式调回主队列
                DispatchQueue.main.async {
                    
                    do{
                        try device.lockForConfiguration()
                        //修改exposureMode
                        device.exposureMode = .locked
                        device.unlockForConfiguration()
                    }catch let error as NSError {
                        self.delegate?.deviceConfigurationFailed(withError: error)
                    }
                }
            }
        }else{
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}


// MARK: - 用于设置,配置视频捕捉会话
extension ZTCameraController {
    
    func setupSession(error: NSError) -> Bool {
        //创建捕捉会话,AVCaptureSession
        captureSession = AVCaptureSession()
        //设置图像分辨率
        captureSession?.sessionPreset = .high
        
        //拿到默认视频捕捉设备,iOS返回后置摄像头
        let videoDevice = AVCaptureDevice.default(for: .video)
        
        //将捕捉设备封装成AVCaptureDeviceInput(为会话添加捕捉设备,必须将设备封装成AVCaptureDeviceInput对象)
        if let videoDevice = videoDevice {
            do {
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                if self.captureSession?.canAddInput(videoInput) == true{
                    //将video 添加到 session中
                    self.captureSession?.addInput(videoInput)
                    self.activeVideoInput = videoInput
                }
            }catch _ as NSError {
                return false
            }
        }
        
        //选择默认音频捕捉设备,即返回一个默认麦克风
        let audioDevice = AVCaptureDevice.default(for: .audio)
        
        //为这个设备创建一个捕捉设备输入
        if let audioDevice = audioDevice {
            do {
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if self.captureSession?.canAddInput(audioInput) == true {
                    //将audioInput 添加到 captureSession中
                    self.captureSession?.addInput(audioInput)
                }
            }catch _ as NSError {
                return false
            }
        }
        
        //AVCapturePhotoOutput实例从摄像头捕捉静态图片
        self.imageOutput = AVCapturePhotoOutput()
//拍摄
//        var photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])
//        photoSettings.flashMode = self.flashMode
//        self.imageOutput?.capturePhoto(with: photoSettings, delegate: nil)
        if self.captureSession?.canAddOutput(self.imageOutput!) == true {
            self.captureSession?.addOutput(self.imageOutput!)
        }
        
        //创建一个AVCaptureMovieFileOutput实例,用于将Quick Time 电影录制到文件系统
        self.movieOutPut = AVCaptureMovieFileOutput()
        
        //输出连接,判断是否可用,可用则添加到输出连接中
        if self.captureSession?.canAddOutput(self.movieOutPut!) == true {
            self.captureSession?.addOutput(self.movieOutPut!)
        }
        
        return true
        
    }
    
    func startSession() {
        
        
        guard let captureSession = self.captureSession else {
            return
        }
        //检查是否处于运行状态
        if !captureSession.isRunning {
            videoQueue.async {
                captureSession.startRunning()
            }
        }
    }
    
    func stopSession() {
        
        guard let captureSession = self.captureSession else {
            return
        }
        //检查是否处于运行状态
        if captureSession.isRunning {
            videoQueue.async {
                captureSession.stopRunning()
            }
        }
    }
    
    
    
    //聚焦.曝光,重设聚焦,曝光的方法
    func focusAt(point: CGPoint) {
        
        guard let device = self.activeCamera() else {
            return
        }
        //是否支持对焦 & 是否自动对焦
        if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
            
            //锁定设备准备配置,如果获得了锁
            do {
                try device.lockForConfiguration()
                //将focusPointOfInterest属性设置成poing
                device.focusPointOfInterest = point
                device.focusMode = .autoFocus
                //释放锁定
                device.unlockForConfiguration()
            }catch let error as NSError {
                delegate?.deviceConfigurationFailed(withError: error)
            }
        }
        
    }
    func exposeAt(point: CGPoint) {
        
        guard let device = self.activeCamera() else {
            return
        }
        let exposureMode: AVCaptureDevice.ExposureMode = .autoExpose
        
        //判断设备是否支持autoExpose模式
        if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
            
            do {
                //锁定设备准备配置
                try device.lockForConfiguration()
                //配置
                device.exposurePointOfInterest = point
                device.exposureMode = .autoExpose
                //判断设备是否支持锁定曝光的模式
                if device.isExposureModeSupported(.locked) {
                    //支持,则使用kvo确定设备的adjustingExposure属性状态
                    device.addObserver(self, forKeyPath: "adjustingExposure", options: .new, context: &ZTThumbnailCreatedNotification)
                }
                device.unlockForConfiguration()
                
                
            }catch let error as NSError {
                delegate?.deviceConfigurationFailed(withError: error)
            }
        }
    }
    func resetFocusAndExposureModes() {
        
        guard let device = self.activeCamera() else {return}
        
        let focusMode:AVCaptureDevice.FocusMode = .autoFocus
        //获取对焦 和 自动对焦模式是或否呗支持
        let canResetFocus = device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode)
        
        let exposureMode: AVCaptureDevice.ExposureMode = .autoExpose
        //确认曝光度可以被重设
        let canResetExposure = device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode)
        
        //捕捉设备空间左上角{0,0} 右下角{1,1},中心点{0.5,0.5}
        let centPoint = CGPoint(x: 0.5, y: 0.5)
        do {
            try device.lockForConfiguration()
            //焦点可设置,则修改
            if canResetFocus {
                device.focusMode = focusMode
                device.focusPointOfInterest = centPoint
            }
            //曝光度可设置,则设置好为期望的曝光模式
            if canResetExposure {
                device.exposureMode = exposureMode
                device.exposurePointOfInterest = centPoint
            }
            device.unlockForConfiguration()
        } catch let error as NSError {
            self.delegate?.deviceConfigurationFailed(withError: error)
        }
        
    }
    
    //捕捉静态图片
    func captureStillImage() {
        
        //获取链接
        guard let connection:AVCaptureConnection = self.imageOutput?.connection(with: .video) else {
            return
        }
        //判断是否支持和设置视频方向
        if connection.isVideoOrientationSupported {
            //获取方向值
            connection.videoOrientation = currentVideoOrientation()
        }
        
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.flashMode = self.flashMode
        self.imageOutput?.capturePhoto(with: photoSettings, delegate: self)
    }
    
    //视频录制
    //开始录制
    func startRecording() {
        
        if !self.isRecording() {
            
            //获取当前视频捕捉链接信息,用于捕捉视频数据配置的一些核心属性
            guard let videoConnection = self.movieOutPut?.connection(with: .video) else {
                return
            }
            
            //判断是否支持 videoOrientation 属性
            if videoConnection.isVideoOrientationSupported {
                //修改视频方向
                videoConnection.videoOrientation = self.currentVideoOrientation()
            }
            
            //判断是否支持视频稳定,可以显著提高视频的质量,只会在录制视频文件涉及
            if videoConnection.isVideoStabilizationSupported {
//                videoConnection.enablesVideoStabilizationWhenAvailable = true
                videoConnection.preferredVideoStabilizationMode = .auto
            }
            
            if let device = self.activeCamera() {
                //摄像头可以进行平滑对焦模式,即减慢摄像头对焦速度,当用户移动拍摄时摄像头会尝试可快速自动对焦
                if device.isSmoothAutoFocusEnabled {
                    do {
                        try device.lockForConfiguration()
                        device.isSmoothAutoFocusEnabled = true
                        device.unlockForConfiguration()
                    }catch let error as NSError {
                        delegate?.deviceConfigurationFailed(withError: error)
                    }
                }
            }
            
            //查找写入捕捉视频的唯一文件系统url
            self.outPutURL = self.uniqueUrl()
            if let url = self.outPutURL {
                self.movieOutPut?.startRecording(to: url as URL, recordingDelegate: self)
            }
            
            
        }
    }
    //停止录制
    func stopRecording() {
        
        if self.isRecording() {
            self.movieOutPut?.stopRecording()
        }
    }
    
    //获取录制状态
    func isRecording() -> Bool {
        guard let output = self.movieOutPut else {
            return false
        }
        return output.isRecording
    }
    //录制时间
    func RecordedDuration() -> CMTime {
        guard let output = self.movieOutPut else {
            return CMTime()
        }
        return output.recordedDuration
        
    }
    
    
    func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation:AVCaptureVideoOrientation
        //获取UIDevice的orientation
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = .portrait
        case .landscapeRight:
            orientation = .landscapeRight
        case .portraitUpsideDown:
            orientation = .portraitUpsideDown
        default:
            orientation = .landscapeLeft
        }
        return orientation
    }
    
    func uniqueUrl() -> NSURL? {
        
        let fileManager = FileManager.default
        
        if let dirPath = fileManager.temporaryDirectory(withTemplateString: "camera.tony") {
            let filePaht = NSString(string: dirPath).appendingPathComponent("camera_movie.mov")
            return NSURL(fileURLWithPath: filePaht)
        }
        return nil
        
    }
    
}

extension ZTCameraController:AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else {
            print("photo null ======")
            return
        }
        if let image = UIImage(data: data) {
            self.writeImageToAsseetsLibrary(image: image)
        }
    }
}


// MARK: - 切换摄像头
extension ZTCameraController {

    fileprivate func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        
        //iOS10之前
//        var devices = AVCaptureDevice.devices(for: .video)
        
        //获取可用视频设备
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: position)
        let devices = discoverySession.devices
        for device: AVCaptureDevice in devices {
            if device.position == position{
                return device
            }
        }
        
        return nil
    }
    
    fileprivate func activeCamera() -> AVCaptureDevice? {
        
        //返回当前捕捉会话对应的摄像头的device属性
        return self.activeVideoInput?.device
    }
    
    //返回当前为激活的摄像头
    fileprivate func inactiveCamera() -> AVCaptureDevice? {
        
        //通过查找当前激活摄像头的反向摄像头获得,如果设备只有一个摄像头,则返回nil
        var device: AVCaptureDevice?
        if self.cameraCount > 1 {
            if self.activeCamera()?.position == AVCaptureDevice.Position.back {
                device = self.cameraWithPosition(position: .front)
            }else{
                device = self.cameraWithPosition(position: .back)
            }
        }
        
        return device
        
    }
    
    func switchCameras() -> Bool {
        
        if !self.canSwitchCameras() {
            return false
        }
        
        //获取当前设备的反向设备
        let videoDevice = self.inactiveCamera()
        
        if let videoDevice = videoDevice {
            do {
                //将输入设备封装成AVCaptureDeviceInput
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                //标注原配置开始变化
                self.captureSession?.beginConfiguration()
                //将捕捉会话中,原本的捕捉输入设备移除
                if let activeVideoInput = self.activeVideoInput {
                    self.captureSession?.removeInput(activeVideoInput)
                }
                
                //判断设备是否能加入
                if self.captureSession?.canAddInput(videoInput) == true {
                    //能则加入,将videoinput作为新的视频捕捉设备
                    self.captureSession?.addInput(videoInput)
                    self.activeVideoInput = videoInput
                }else{
                    //如果无法加入,则将原本视频捕捉设备重新加入
                    if let activeVideoInput = self.activeVideoInput {
                        self.captureSession?.addInput(activeVideoInput)
                    }
                }
                //配置完成后,commitConfiguration方法会分批的将所有变更整合
                self.captureSession?.commitConfiguration()
                
                
                
            }catch let error as NSError {
                delegate?.deviceConfigurationFailed(withError: error)
                return false
            }
            
            return true
        }else{
            return false
        }
        
        
    }
    
    func canSwitchCameras() -> Bool {
        
        return self.cameraCount > 1
    }
    
}


extension ZTCameraController {
    
    func writeImageToAsseetsLibrary(image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { (isSuccess, error) in
            if isSuccess {
                print("保存成功")
                self.postThumbnailNotification(image: image)
            }else{
                print("保存失败: \(String(describing: error?.localizedDescription))")
            }
        }
    }
    
    func postThumbnailNotification(image: UIImage) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name(ZTThumbnailCreatedNotification), object: image)
        }
    }
    
    //写入捕捉的视频
    func writeVideoToAssetsLibrary(videoUrl: NSURL) -> Void {
        
        guard let path = videoUrl.path else {
            return
        }
        //写资源库前,检查是否可以被写入
        if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path) {
            
            PHPhotoLibrary.shared().performChanges({
                let create = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl as URL)
                self.localIdentifier = create?.placeholderForCreatedAsset?.localIdentifier
                
            }, completionHandler: { (isSuccess, error) in
                if isSuccess {
                    print("保存成功")
                    if self.localIdentifier != nil {
                        self.generateThumbnailForVideo(identifier: self.localIdentifier!)
                        self.localIdentifier = nil
                    }
                    
                }else{
                    print("保存失败: \(String(describing: error?.localizedDescription))")
                }
            })
        }
        
        
    }
    
    //获取视频缩略图,资源的identifier,phphotokit框架使用identifier来区分资源
    func generateThumbnailForVideo(identifier: String) {
        self.videoQueue.async {
            
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
            print(assets.count)
            if let asset = assets.firstObject {
                PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFit, options: nil, resultHandler: { (image, dict) in
                    if let img = image {
                        self.postThumbnailNotification(image: img)
                    }
                    
                })
            }
            
        }
    }
    
}


extension ZTCameraController : AVCaptureFileOutputRecordingDelegate {
    
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        NotificationCenter.post(customNotification: .startRecording)
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        print("=======================")
        NotificationCenter.post(customNotification: .stopRecording)
        if let error = error {
            delegate?.mediaCaptureFailed(withError: error as NSError)
        }else {
            if let url = self.outPutURL {
                //写入视频
                self.writeVideoToAssetsLibrary(videoUrl: url)
            }
            
        }
    }
    
}

