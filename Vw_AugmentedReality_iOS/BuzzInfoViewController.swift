//
//  BuzzInfoViewController.swift
//  arVW
//
//  Created by Swathi Thippireddy on 10/11/23.
//

import UIKit
import SlidingTabView
import SwiftUI

class BuzzInfoViewController: UIViewController, UITableViewDelegate{

    @IBSegueAction func embedSwiftUIView(_ coder: NSCoder) -> UIViewController? {
        return UIHostingController(coder: coder, rootView: BuzzInfoView())
    }
    
    var car = "buzz"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    //        self.BuzzSpecsTableView.
    }
    
}

struct BuzzInfoView: View{
    @State private var tabIndex = 0
    let color = Color("launch-screen-background")
    var body: some View {
        VStack{
            //            if #available(iOS 14.0.0, *){
            SlidingTabView(selection: self.$tabIndex,
                           tabs: ["Key Specs", "Dimensions", "Engine", "Additional"],
                           font: .system(size: 14, weight: .semibold),
                           //                               animation: .easeInOut,
                           activeAccentColor: color, //category text color
                           selectionBarColor: color){
                Text("Buzz offers a net energy content of 77 kWh (gross: 82 kWh). You can travel up to 258 miles without recharging 5. The maximum charging power for fast charging (DC) is up to 170 kW. At this charging rate, it only takes around 30 minutes to charge the battery from 5% to 80% 6.")
                Text("At 2,988 mm (117.6 in), the wheelbase of the ID. Buzz (SWB) is similar to that of the current Volkswagen Transporter (T6); it is 81 mm (3.2 in) wider than the T6 and features a turning circle of 11.1 m (36 ft), which is approximately the same as a Golf.")
                Text("The short-wheelbase (SWB) version is equipped with rear-axle APP 310 motor with an output of 150 kW (201 hp) and 310 N⋅m (229 lb⋅ft).")
                Text("The SWB/RWD version has an 81 kW-hr battery, of which 77 kW-hr are usable; the estimated driving range is 400–480 km (250–300 mi).")
            }
//        }

        }
    }
    
}
    
//@available(iOS 14.0.0, *)
//struct BuzzInfoView_Previews: PreviewProvider {
//    static var previews: some View {
//        BuzzInfoView()
//    }
//}
