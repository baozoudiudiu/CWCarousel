//
//  SViewController.swift
//  CWCarousel
//
//  Created by WangChen on 2018/4/3.
//  Copyright © 2018年 ChenWang. All rights reserved.
//

import UIKit

class SViewController : UIViewController {
    override func viewDidLoad() {
        self.configureUI()
    }
    
    private func configureUI () {
        self.view.backgroundColor = UIColor.white
        self.listView.tableFooterView = UIView.init()
    }
    
    override func didReceiveMemoryWarning() {
        
    }
    //MARK: - Property
    @IBOutlet weak var listView: UITableView!
    /// 选项数据源
    let titles = ["默认样式"]
}

extension SViewController: UITableViewDelegate, UITableViewDataSource {
    // cell selected
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    // cell numbers
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.titles.count
    }
    // cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let idStr = "cellId"
        var cell = tableView.dequeueReusableCell(withIdentifier: idStr)
        if cell == nil {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: idStr)
            cell?.accessoryType = .disclosureIndicator
        }
        cell?.textLabel?.text = self.titles[indexPath.row]
        return cell!
    }
    // cell height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}
