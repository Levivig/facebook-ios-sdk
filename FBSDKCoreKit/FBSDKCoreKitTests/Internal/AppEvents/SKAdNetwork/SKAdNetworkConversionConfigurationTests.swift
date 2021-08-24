// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#if !os(tvOS)

class SKAdNetworkConversionConfigurationTests: XCTestCase {
  func testInit() {
    // Init with nil
    var config = SKAdNetworkConversionConfiguration(json: nil)
    XCTAssertNil(config)

    // Init with invalid data
    var invalidData = [String: Any]()
    config = SKAdNetworkConversionConfiguration(json: invalidData)
    XCTAssertNil(config)

    invalidData = [
      "data": [
        [
          "timer_buckets": 1,
          "timer_interval": 1000,
          "default_currency": "usd",
          "cutoff_time": 2
        ]
      ]
    ]
    config = SKAdNetworkConversionConfiguration(json: invalidData)
    XCTAssertNil(config)

    invalidData = [
      "data": [
        [
          "timer_buckets": 1,
          "timer_interval": 1000,
          "cutoff_time": 2,
          "conversion_value_rules": []
        ]
      ]
    ]
    config = SKAdNetworkConversionConfiguration(json: invalidData)
    XCTAssertNil(config)

    // Init with valid data
    let validData = [
      "data": [
        [
          "timer_buckets": 1,
          "timer_interval": 1000,
          "default_currency": "usd",
          "cutoff_time": 2,
          "conversion_value_rules": []
        ]
      ]
    ]

    config = SKAdNetworkConversionConfiguration(json: validData)
    XCTAssertNotNil(config)
    XCTAssertEqual(1, config?.timerBuckets)
    XCTAssertEqual(2, config?.cutoffTime)
    XCTAssertEqual(config?.defaultCurrency, "USD")
    XCTAssertEqual(1000, config?.timerInterval ?? 0, accuracy: 0.001)
  }

  func testParseRules() throws { // swiftlint:disable:this function_body_length
    let rules = [
      [
        "conversion_value": 2,
        "events": [
          [
            "event_name": "fb_mobile_purchase"
          ]
        ]
      ],
      [
        "conversion_value": 4,
        "events": [
          [
            "event_name": "fb_mobile_purchase",
            "values": [
              [
                "currency": "USD",
                "amount": 100
              ]
            ]
          ]
        ]
      ],
      [
        "conversion_value": 3,
        "events": [
          [
            "event_name": "fb_mobile_purchase",
            "values": [
              [
                "currency": "USD",
                "amount": 100
              ],
              [
                "currency": "JPY",
                "amount": 100
              ]
            ]
          ]
        ]
      ]
    ]

    let conversionBitRules = try XCTUnwrap(SKAdNetworkConversionConfiguration.parseRules(rules))
    var expectedRules = [SKAdNetworkRule]()

    expectedRules.append(try XCTUnwrap(
      SKAdNetworkRule(json: [
        "conversion_value": 4,
        "events": [
          [
            "event_name": "fb_mobile_purchase",
            "values": [
              [
                "currency": "USD",
                "amount": 100
              ]
            ]
          ]
        ]
      ])
    ))

    expectedRules.append(try XCTUnwrap(
      SKAdNetworkRule(json: [
        "conversion_value": 3,
        "events": [
          [
            "event_name": "fb_mobile_purchase",
            "values": [
              [
                "currency": "USD",
                "amount": 100,
              ],
              [
                "currency": "JPY",
                "amount": 100,
              ]
            ]
          ]
        ]
      ])
    ))

    expectedRules.append(try XCTUnwrap(
      SKAdNetworkRule(json: [
        "conversion_value": 2,
        "events": [
          [
            "event_name": "fb_mobile_purchase"
          ]
        ]
      ])
    ))

    for (expectedRule, parsedRule) in zip(expectedRules, conversionBitRules) {
      XCTAssertEqual(expectedRule.conversionValue, parsedRule.conversionValue)
      XCTAssertEqual(expectedRule.events.count, parsedRule.events.count)

      for (expectedEvent, parsedEvent) in zip(expectedRule.events, parsedRule.events) {
        XCTAssertEqual(expectedEvent.eventName, parsedEvent.eventName)

        XCTAssertEqual(expectedEvent.values, parsedEvent.values) // nil or equal
      }
    }

    XCTAssertNil(SKAdNetworkConversionConfiguration.parseRules(nil))

    let invalidData = [
      [
        "conversion_value": 2,
        "events": [
          [
            "event_name": "fb_mobile_purchase",
            "values": [
              [
                "amount": 100
              ]
            ]
          ]
        ]
      ],
      [
        "conversion_value": 3,
        "events": [
          [
            "event_name": "fb_mobile_purchase",
            "values": [
              [
                "currency": "USD",
                "amount": 100
              ]
            ]
          ]
        ]
      ]
    ]
    XCTAssertEqual(1, SKAdNetworkConversionConfiguration.parseRules(invalidData)?.count)
  }

  func testEventSet() {
    let data: [String: Any] = [
      "data": [
        [
          "timer_buckets": 1,
          "timer_interval": 1000,
          "cutoff_time": 2,
          "default_currency": "usd",
          "conversion_value_rules": [
            [
              "conversion_value": 2,
              "events": [
                [
                  "event_name": "fb_mobile_purchase"
                ]
              ]
            ],
            [
              "conversion_value": 4,
              "events": [
                [
                  "event_name": "fb_mobile_purchase",
                  "values": [
                    [
                      "currency": "USD",
                      "amount": 100
                    ]
                  ]
                ],
                [
                  "event_name": "fb_mobile_complete_registration",
                  "values": [
                    [
                      "currency": "EU",
                      "amount": 100
                    ]
                  ]
                ],
              ],
            ],
            [
              "conversion_value": 3,
              "events": [
                [
                  "event_name": "fb_mobile_purchase",
                  "values": [
                    [
                      "currency": "USD",
                      "amount": 100
                    ],
                    [
                      "currency": "JPY",
                      "amount": 100
                    ]
                  ]
                ],
                [
                  "event_name": "fb_mobile_search",
                ]
              ],
            ],
          ]
        ]
      ]
    ]

    let config = SKAdNetworkConversionConfiguration(json: data)
    let expected = Set(["fb_mobile_search", "fb_mobile_purchase", "fb_mobile_complete_registration"])
    XCTAssertEqual(config?.eventSet, expected)
  }

  func testCurrencySet() {
    let data: [String: Any] = [
      "data": [
        [
          "timer_buckets": 1,
          "timer_interval": 1000,
          "cutoff_time": 2,
          "default_currency": "usd",
          "conversion_value_rules": [
            [
              "conversion_value": 2,
              "events": [
                [
                  "event_name": "fb_mobile_purchase",
                ]
              ],
            ],
            [
              "conversion_value": 4,
              "events": [
                [
                  "event_name": "fb_mobile_purchase",
                  "values": [
                    [
                      "currency": "USD",
                      "amount": 100
                    ]
                  ]
                ],
                [
                  "event_name": "fb_mobile_complete_registration",
                  "values": [
                    [
                      "currency": "eu",
                      "amount": 100
                    ]
                  ]
                ],
              ],
            ],
            [
              "conversion_value": 3,
              "events": [
                [
                  "event_name": "fb_mobile_purchase",
                  "values": [
                    [
                      "currency": "usd",
                      "amount": 100
                    ],
                    [
                      "currency": "jpy",
                      "amount": 100
                    ]
                  ]
                ],
                [
                  "event_name": "fb_mobile_search",
                ]
              ],
            ],
          ]
        ]
      ]
    ]

    let config = SKAdNetworkConversionConfiguration(json: data)
    let expected = Set(["USD", "EU", "JPY"])
    XCTAssertEqual(config?.currencySet, expected)
  }
}

#endif
