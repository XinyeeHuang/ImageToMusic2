//
//  ViewController.swift
//  ImageToMusic
//
//  Created by Iris on 2019/1/11.
//  Copyright © 2019 HuangXinyi. All rights reserved.
//  

import UIKit

class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    var image: UIImage!
    //图片是否加载成功，页面可以跳转
    var canTurn = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    
    @IBAction func uploadImage(_ sender: Any) {
        selectImage()
    }
    
    //MARK: 上传图片
    //选取相册
    func selectImage(){
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
            picker.allowsEditing = false
            self.present(picker, animated: true, completion: nil)
        } else {
            print("无法读取相册")
        }
    }
    
    //选取图片完成
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        print(info)
        image = info[.originalImage] as? UIImage
        //将图片显示在视图中
        imageView.image = image
        //图片控制器退出
        picker.dismiss(animated: true, completion: nil)
        canTurn = true
    }
    
    //取消选择
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("已取消")
        picker.dismiss(animated: true, completion: nil)
    }
    
    
    
    //MARK: 页面跳转
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination
        if let colorPickerVC = destinationVC as? ColorPickerViewController, segue.identifier == "didUpload", canTurn == true {
            //成功加载图片之后才能跳转，使用canTurn作为是否跳转的条件
            //【尝试不用两个按钮，上传图片成功后自动跳转的方法】
            colorPickerVC.userImage = image
        } else {
            //若未成功上传，提示用户上传图片
            let alert = UIAlertController(title: "提示", message: "请先上传图片", preferredStyle: .alert)
            let action = UIAlertAction(title: "好", style: .default, handler: nil)
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
        }
    }
}

