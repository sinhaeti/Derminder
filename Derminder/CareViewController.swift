/*
 Copyright (c) 2019, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3. Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import Foundation
import UIKit
import CareKit

class CareViewController: OCKDailyPageViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem =
            UIBarButtonItem(title: "Care Team", style: .plain, target: self,
                            action: #selector(presentContactsListViewController))
    }

    @objc private func presentContactsListViewController() {
        let viewController = OCKContactsListViewController(storeManager: storeManager)
        viewController.title = "Care Team"
        viewController.isModalInPresentation = true
        viewController.navigationItem.rightBarButtonItem =
            UIBarButtonItem(title: "Done", style: .plain, target: self,
                            action: #selector(dismissContactsListViewController))

        let navigationController = UINavigationController(rootViewController: viewController)
        present(navigationController, animated: true, completion: nil)
    }

    @objc private func dismissContactsListViewController() {
        dismiss(animated: true, completion: nil)
    }

    // This will be called each time the selected date changes.
    // Use this as an opportunity to rebuild the content shown to the user.

    override func dailyPageViewController(_ dailyPageViewController: OCKDailyPageViewController,
                                          prepare listViewController: OCKListViewController, for date: Date) {

        let identifiers = ["doxylamine", "nausea", "kegels"]
        var query = OCKTaskQuery(for: date)
        query.ids = identifiers
        query.excludesTasksWithNoEvents = true

        storeManager.store.fetchAnyTasks(query: query, callbackQueue: .main) { result in
            switch result {
            case .failure(let error): print("Error: \(error)")
            case .success(let tasks):

                // Add a non-CareKit view into the list
                let tipTitle = "Benefits of sunscreen"
                let tipText = "Learn how sunscreen can help keep your skin protected."

                // Only show the tip view on the current date
                if Calendar.current.isDate(date, inSameDayAs: Date()) {
                    let tipView = TipView()
                    tipView.headerView.titleLabel.text = tipTitle
                    tipView.headerView.detailLabel.text = tipText
                    tipView.imageView.image = UIImage(named: "exercise.png")
                    listViewController.appendView(tipView, animated: false)
                }

                // Since the kegel task is only sheduled every other day, there will be cases
                // where it is not contained in the tasks array returned from the query.
                if let kegelsTask = tasks.first(where: { $0.id == "kegels" }) {
                    let kegelsCard = OCKSimpleTaskViewController(task: kegelsTask, eventQuery: .init(for: date),
                                                                 storeManager: self.storeManager)
                    listViewController.appendViewController(kegelsCard, animated: false)
                }

                // Create a card for the doxylamine task if there are events for it on this day.
                if let doxylamineTask = tasks.first(where: { $0.id == "doxylamine" }) {
                    let doxylamineCard = OCKChecklistTaskViewController(task: doxylamineTask, eventQuery: .init(for: date),
                                                                        storeManager: self.storeManager)
                    listViewController.appendViewController(doxylamineCard, animated: false)
                }

                // Create a card for the nausea task if there are events for it on this day.
                // Its OCKSchedule was defined to have daily events, so this task should be
                // found in `tasks` every day after the task start date.
                if let nauseaTask = tasks.first(where: { $0.id == "nausea" }) {

                    // dynamic gradient colors
                    let nauseaGradientStart = UIColor { traitCollection -> UIColor in
                        return traitCollection.userInterfaceStyle == .light ? #colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1) : #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
                    }
                    let nauseaGradientEnd = UIColor { traitCollection -> UIColor in
                        return traitCollection.userInterfaceStyle == .light ? #colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1) : #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
                    }

                    // Create a plot comparing nausea to medication adherence.
                    let nauseaDataSeries = OCKDataSeriesConfiguration(
                        taskID: "nausea",
                        legendTitle: "Flare Ups",
                        gradientStartColor: nauseaGradientStart,
                        gradientEndColor: nauseaGradientEnd,
                        markerSize: 10,
                        eventAggregator: OCKEventAggregator.countOutcomeValues)

                    let doxylamineDataSeries = OCKDataSeriesConfiguration(
                        taskID: "doxylamine",
                        legendTitle: "Fluocinonide",
                        gradientStartColor: UIColor { traitCollection -> UIColor in
                            return traitCollection.userInterfaceStyle == .light ? #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1) : #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
                        },
                        gradientEndColor: UIColor { traitCollection -> UIColor in
                            return traitCollection.userInterfaceStyle == .light ? #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1) : #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
                        },
                        markerSize: 10,
                        eventAggregator: OCKEventAggregator.countOutcomeValues)

                    let insightsCard = OCKCartesianChartViewController(plotType: .bar, selectedDate: date,
                                                                       configurations: [nauseaDataSeries, doxylamineDataSeries],
                                                                       storeManager: self.storeManager)
                    insightsCard.chartView.headerView.titleLabel.text = "Sunscreen & Topical Medicine Application"
                    insightsCard.chartView.headerView.detailLabel.text = "This Week"
                    insightsCard.chartView.headerView.accessibilityLabel = "Sunscreen & Topical Medicine Application, This Week"
                    listViewController.appendViewController(insightsCard, animated: false)

                    // Also create a card that displays a single event.
                    // The event query passed into the initializer specifies that only
                    // today's log entries should be displayed by this log task view controller.
                    let nauseaCard = OCKButtonLogTaskViewController(task: nauseaTask, eventQuery: .init(for: date),
                                                                    storeManager: self.storeManager)
                    listViewController.appendViewController(nauseaCard, animated: false)
                }
            }
        }
    }
}
