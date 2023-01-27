//
//  UPnPDeviceSearchViewController.swift
//  UPnPDA_Example
//
//  Created by 王海洋 on 2020/2/26.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import UPnPDA
import HiNetWork
import AEXML
private let UPnPDeviceCellId = "UPnPDeviceCellId"
class UPnPDeviceSearchViewController: UIViewController {
    lazy var UPNPControlPoint : UPnPDeviceControlPoint = {
        let controlPoint = UPnPDeviceControlPoint()
        controlPoint.delegate = self
        return controlPoint
    }()
        
    lazy var demoApiManager: DemoAPIManager = {
        let demoApiManager = DemoAPIManager()
        demoApiManager.resultDelegate = self
        demoApiManager.paramsSource = self
        return demoApiManager
    }()
    
    lazy var table: UITableView = {
        let table = UITableView(frame: view.bounds, style: .plain)
        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: UPnPDeviceCellId)
        return table
    }()
    
    lazy var serviceSearcher: UPnPServiceSearch = {
        let search = UPnPServiceSearch()
        search.searchTarget = M_SEARCH_Targert.all()
        search.delegate = self
        return search
    }()
    
    private var upnpDeviceList:[UPnPDeviceDescriptionDocument] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(table)
        
        ///
        let _ = demoApiManager.loadData()
        
        serviceSearcher.start()
        browseMoviesFolder()
        
        // Do any additional setup after loading the view.
    }
    
    func browseRoot() {
        let controlUrl = "http://192.168.0.7:8096/dlna/e15a1e07-f7ad-4a1f-ba96-c67fdb04eb2d/contentdirectory/control"
        let serviceType = "urn:schemas-upnp-org:service:ContentDirectory:1"
        var action = UPnPAction(controlUrl: controlUrl, serviceType: serviceType)
        action.setAction("Browse")
        action.setArgument("0", for: "ObjectID")
        action.setArgument("BrowseDirectChildren", for: "BrowseFlag")
        action.setArgument("*", for: "Filter")
        action.setArgument("0", for: "StartingIndex")
        action.setArgument("0", for: "RequestedCount")
        action.setArgument("", for: "SortCriteria")
        UPNPControlPoint.invoke(action: action)
    }
    
    func browseJellyDesk() {
        let controlUrl = "http://192.168.0.7:8096/dlna/e15a1e07-f7ad-4a1f-ba96-c67fdb04eb2d/contentdirectory/control"
        let serviceType = "urn:schemas-upnp-org:service:ContentDirectory:1"
        var action = UPnPAction(controlUrl: controlUrl, serviceType: serviceType)
        action.setAction("Browse")
        action.setArgument("9b968eeb7e5517ad962b38c798329aea", for: "ObjectID")
        action.setArgument("BrowseDirectChildren", for: "BrowseFlag")
        action.setArgument("*", for: "Filter")
        action.setArgument("0", for: "StartingIndex")
        action.setArgument("0", for: "RequestedCount")
        action.setArgument("", for: "SortCriteria")
        UPNPControlPoint.invoke(action: action)
    }
    
    func browseMoviesFolder() {
        let controlUrl = "http://192.168.0.7:8096/dlna/e15a1e07-f7ad-4a1f-ba96-c67fdb04eb2d/contentdirectory/control"
        let serviceType = "urn:schemas-upnp-org:service:ContentDirectory:1"
        var action = UPnPAction(controlUrl: controlUrl, serviceType: serviceType)
        action.setAction("Browse")
        action.setArgument("movies_9b968eeb7e5517ad962b38c798329aea", for: "ObjectID")
        action.setArgument("BrowseDirectChildren", for: "BrowseFlag")
        action.setArgument("*", for: "Filter")
        action.setArgument("0", for: "StartingIndex")
        action.setArgument("0", for: "RequestedCount")
        action.setArgument("", for: "SortCriteria")
        UPNPControlPoint.invoke(action: action)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: UITableView DataSource and Delegate Methods
extension UPnPDeviceSearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return upnpDeviceList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UPnPDeviceCellId, for: indexPath)
        for subview in cell.contentView.subviews {
            subview.removeFromSuperview()
        }
        let device = upnpDeviceList[indexPath.row]
        let nameLabel = UILabel(frame: CGRect(x: 20, y: 0, width: 300, height: 50))
        nameLabel.numberOfLines = 0
        if let name = device.friendlyName, let ip = device.ip {
            nameLabel.text = "\(name) \n \(ip)"
        }
        cell.contentView.addSubview(nameLabel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let deviceDecDoc = upnpDeviceList[indexPath.row]
        
        let avTransPortVc = AVTransportViewController()
        avTransPortVc.deviceDesDoc = deviceDecDoc
        navigationController?.show(avTransPortVc, sender: self)
        
        
    }
    
}

extension UPnPDeviceSearchViewController: UPnPDeviceControlPointDelegate {
    func controlSuccess(_ controlPoint: UPnPDA.UPnPDeviceControlPoint, response data: Data) {
        parse(data)
    }
    
    func controlFaild(_ controlPoint: UPnPDA.UPnPDeviceControlPoint, error: Error) {
        print("failed")
    }
    
    private func parse(_ data: Data) {
        
        do {
            let xmlDoc = try AEXMLDocument(xml: data, options: AEXMLOptions())
            //print("response xml : \(xmlDoc.xml)")

            let children = xmlDoc.root.children
            if children.count > 0 {
                let bodyElement = children[0]
                if bodyElement.name.hasSuffix("Body") {
                    parseBodyElement(element: bodyElement)
                }
            }
        } catch {
            // error
//            let upnpError = UPnpActionError(faultCode: "-", faultString: "-", errorCode: "", errorDescription: "Parse XML data error : \(error.localizedDescription)")
//            onError(upnpError)
        }
    }
    
    private func parseBodyElement(element: AEXMLElement) {
        
        for childElement in element.children {
            let elementName = childElement.name
        
            print("UPnP Action Response to \(elementName)")
            print("UPnP Action Response ：\n\(childElement.xml)")
            
            //dump(childElement.children)
            for e in childElement.children {
                if e.name.hasSuffix("Result") {
                    //dump(e.value)
                    let da = e.value?.data(using: .utf8)
                    let xmlDoc = try? AEXMLDocument(xml: da!, options: AEXMLOptions())
                    //dump(xmlDoc)
                    for child in xmlDoc!.root.children {
                        for c in child.children {
                            if c.name == "res" {
                                print(c.value)
                                //Finally the value for video url
                            }
                        }
                    }
                }
            }
        }
    }
    
}

// MARK: UPnP Device Search Delegate
extension UPnPDeviceSearchViewController: UPnPServiceSearchDelegate {
    
    func serviceSearch(_ serviceSearch: UPnPServiceSearch, upnpDevices devices: [UPnPDeviceDescriptionDocument]) {
        //dump(devices)
        //print(devices.count)
        for d in devices {
            //print(d.deviceType)
            //dump(d.serviceBriefList)
        }
        upnpDeviceList = devices
        table.reloadData()
    }
    
    func serviceSearch(_ serviceSearch: UPnPServiceSearch, dueTo error: Error) {
        print(" Search Occur Error \(error)")
    }
    
    
}


extension UPnPDeviceSearchViewController: HiAPIManagerResultDelegate, HiAPIManagerParameterDelegate {
    func success(_ manager: HiBaseAPIManager) {
        let data:Dictionary<String,Any>? = manager.fetchData(with:nil) as? Dictionary<String, Any>
        //print("result = \(String(describing: data))")
        
    }
    
    func faild(_ manager: HiBaseAPIManager) {
        let faildType = manager.faildType()
        print("Faild = \(faildType)")
        
    }
    
    func parameters(_ manager: HiBaseAPIManager) -> [String : String]? {
         return [
                "apiKey":"123fd90af7904388804555f1090d71db",
                "categoryId":"1",
                "topType":"1",
                "limit":"50"
               ]
    }
    
    
}
