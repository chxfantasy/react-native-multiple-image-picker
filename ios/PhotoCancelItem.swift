//
//  PhotoCancelItem.swift
//  Pods
//
//  Created by BAO HA on 4/12/24.
//

import HXPhotoPicker
import UIKit

extension UIView: HXPickerCompatible {
    var size: CGSize {
        get { frame.size }
        set {
            var rect = frame
            rect.size = newValue
            frame = rect
        }
    }
}

public class PhotoCancelItem: UIView, PhotoNavigationItem {
    public weak var itemDelegate: PhotoNavigationItemDelegate?
    public var itemType: PhotoNavigationItemType { .cancel }
    
    let config: PickerConfiguration
    public required init(config: PickerConfiguration) {
        self.config = config
        super.init(frame: .zero)
        initView()
    }
    
    var button: UIButton!
    func initView() {
        button = UIButton(type: .custom)
    
        // binkoo patch: clean SF Symbol X (no circle), dark tint for light theme
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: symbolConfig), for: .normal)
        button.tintColor = .black
        
        button.addTarget(self, action: #selector(didCancelClick), for: .touchUpInside)
        
        addSubview(button)
        
        // binkoo patch: 用标准 44×44 让自定义视图填满 iOS 26 的玻璃壳，并显式居中，避免 X 偏移
        let itemSize = CGSize(width: 44, height: 44)
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.size = itemSize
        size = itemSize
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        // 兜底：宿主重新布局时把按钮拉满本视图，保证 X 始终居中
        button.frame = bounds
    }
    
    @objc
    func didCancelClick() {
        print("close ne")
        itemDelegate?.photoControllerDidCancel()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
