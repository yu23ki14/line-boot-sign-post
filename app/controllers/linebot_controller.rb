class LinebotController < ApplicationController
  require 'line/bot'
  protect_from_forgery :except => [:webhook]
  
  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
  
  def callback
    body = request.body.read
    events = client.parse_events_from(body)
    events.each { |event|
      case event
      when Line::Bot::Event::Message then
        case event.type
        when Line::Bot::Event::MessageType::Text
          event_content = event.message['text']
          line_user_id = event['source']['userId']
          if event_content == "プランを作りたいです。"
            message = { 
              type: 'flex',
              altText: '人数選択',
              contents: people_num
              }
          elsif event_content.include?("人で行きます。")
            message = { type: 'flex',
                        altText: '性別選択',
                        contents: party_gender
                      }          
          elsif event_content.include?("男性のみ") || event_content.include?("女性のみ") || event_content.include?("男女混合")
            message = {
                type: "text",
                text: "出発時間と帰宅時間を教えてください。（11:00~18:00のように入力してください。）"
              }
          elsif event_content.include?("~") || event_content.include?("～")
            message = {
                type: "flex",
                altText: "趣向選択",
                contents: favorite
              }
          elsif event_content.include?("王道コース") || event_content.include?("穴場コース")
            message = {
                type: "flex",
                altText: "趣向選択",
                contents: sample_plan1
              }
          elsif event_content.include?("座禅に行きたいです。")
            message = {
                type: "flex",
                altText: "趣向選択",
                contents: sample_plan2
              }
          elsif event_content.include?("いちご狩りに行きたいです。")
            message = {
                type: "flex",
                altText: "プラン完了",
                contents: plan_complete
              }
          elsif event_content.include?("プラン作成完了！")
            message = {
                type: "flex",
                altText: "プラン一覧",
                contents: plan_show
              }
          elsif event_content.include?("これで保存！")
            @plan = Arrive.new(:plan => true, :line_user_id => line_user_id)
            if @plan.save
              message = {
                  type: "text",
                  text: "保存完了しました。"
                }
            end
          end
          client.reply_message(event['replyToken'], message)
        end
        
      when Line::Bot::Event::Beacon then
        line_user_id = event['source']['userId']
        @arrive = Arrive.where(line_user_id: line_user_id).where(plan: true).where(arrive: false).last
        if @arrive.present?
          message = {
              type: "text",
              text: "大船駅に到着しました。次の目的地は大船観音寺です。地図はこちらです。\n https://www.google.co.jp/maps/place/%E5%A4%A7%E8%88%B9%E8%A6%B3%E9%9F%B3%E5%AF%BA/@35.3534881,139.5265218,17z/data=!4m5!3m4!1s0x6018455f8e9fe9f7:0xb8b10af5c7d257ed!8m2!3d35.3529738!4d139.5284238"
            }
          @arrive.update(arrive: true)
          client.reply_message(event['replyToken'], message)
          #
          #if @arrive.save
          #  client.reply_message(event['replyToken'], message)
          #end          
        end
      end
    }

    head :ok
  end
  
  def people_num
      message_panel = {
        "type": "bubble",
        "body": {
          "type": "box",
          "layout": "vertical",
          "contents": [
            {
              "type": "text",
              "text": "何人で行きますか？",
              "weight": "bold",
              "size": "lg"
            }
          ]
        },
        "footer": {
          "type": "box",
          "layout": "vertical",
          "spacing": "sm",
          "contents": [
            {
              "type": "box",
              "layout": "horizontal",
              "spacing": "sm",
              "contents": [
                {
                  "type": "button",
                  "action": {
                    "type":"message",
                    "label":"1人",
                    "text":"1人で行きます。"
                  }
                },
                {
                  "type": "button",
                  "action": {
                    "type":"message",
                    "label":"2人",
                    "text":"2人で行きます。"
                  }
                },
                {
                  "type": "button",
                  "action": {
                    "type":"message",
                    "label":"3人",
                    "text":"3人で行きます。"
                  }
                },
                {
                  "type": "button",
                  "action": {
                    "type":"message",
                    "label":"4人",
                    "text":"4人で行きます。"
                  }
                }
              ]
            }
          ],
          "flex": 0
        }
      }
    return message_panel
  end
  
  def party_gender
      message_panel = {
        "type": "bubble",
        "body": {
          "type": "box",
          "layout": "vertical",
          "contents": [
            {
              "type": "text",
              "text": "グループの性別構成は？",
              "weight": "bold",
              "size": "lg"
            }
          ]
        },
        "footer": {
          "type": "box",
          "layout": "vertical",
          "spacing": "sm",
          "contents": [
            {
              "type": "box",
              "layout": "vertical",
              "spacing": "sm",
              "contents": [
                {
                  "type": "button",
                  "action": {
                    "type":"message",
                    "label":"男性のみ",
                    "text":"男性のみで行きます。"
                  }
                },
                {
                  "type": "button",
                  "action": {
                    "type":"message",
                    "label":"女性のみ",
                    "text":"女性のみで行きます。"
                  }
                },
                {
                  "type": "button",
                  "action": {
                    "type":"message",
                    "label":"男女混合",
                    "text":"男女混合で行きます。"
                  }
                }
              ]
            }
          ],
          "flex": 0
        }
      }
    return message_panel
  end
  
  def destination
      message_panel = {
        "type": "bubble",
        "body": {
          "type": "box",
          "layout": "vertical",
          "contents": [
            {
              "type": "text",
              "text": "行先はどこにしますか？",
              "weight": "bold",
              "size": "lg"
            }
          ]
        },
        "footer": {
          "type": "box",
          "layout": "vertical",
          "spacing": "sm",
          "contents": [
            {
              "type": "box",
              "layout": "vertical",
              "spacing": "sm",
              "contents": [
                {
                  "type": "button",
                  "action": {
                    "type":"message",
                    "label":"鎌倉",
                    "text":"鎌倉に行きたいです。"
                  }
                },
                {
                  "type": "button",
                  "action": {
                    "type":"message",
                    "label":"軽井沢",
                    "text":"軽井沢に行きたいです。"
                  }
                },
                {
                  "type": "button",
                  "action": {
                    "type":"message",
                    "label":"お台場",
                    "text":"お台場に行きたいです。"
                  }
                }
              ]
            }
          ],
          "flex": 0
        }
      }
    return message_panel
  end
  
  def favorite
      message_panel = {
        "type": "bubble",
        "body": {
          "type": "box",
          "layout": "vertical",
          "contents": [
            {
              "type": "text",
              "text": "あなたの旅の趣向を教えてください。",
              "weight": "bold",
              "size": "lg",
              "wrap": true
            }
          ]
        },
        "footer": {
          "type": "box",
          "layout": "vertical",
          "spacing": "sm",
          "contents": [
            {
              "type": "box",
              "layout": "vertical",
              "spacing": "sm",
              "contents": [
                {
                  "type": "button",
                  "action": {
                    "type":"message",
                    "label":"王道コース",
                    "text":"王道コース"
                  }
                },
                {
                  "type": "button",
                  "action": {
                    "type":"message",
                    "label":"穴場コース",
                    "text":"穴場コース"
                  }
                }
              ]
            }
          ],
          "flex": 0
        }
      }
    return message_panel
  end
  
  def sample_plan1
    message_panel = {
      "type": "bubble",
      "hero": {
        "type": "image",
        "url": "https://line-boot-sign-post-yu23ki14.c9users.io/assets/ofuna_kannon-ca0fa3a272e4dcd48d3df7d1cd3b5c8beeb9a3d8d77ed1f75376fddecbb2908e.jpg",
        "size": "full",
        "aspectRatio": "20:13",
        "aspectMode": "cover",
        "action": {
          "type": "uri",
          "uri": "http://www.oofuna-kannon.or.jp/"
        }
      },
      "body": {
        "type": "box",
        "layout": "vertical",
        "contents": [
          {
            "type": "text",
            "text": "大船観音寺（座禅会）",
            "weight": "bold",
            "size": "xl"
          },
          {
            "type": "box",
            "layout": "vertical",
            "margin": "lg",
            "spacing": "sm",
            "contents": [
              {
                "type": "text",
                "text": "大きな観音像がある大船観音寺で座禅ができます。",
                "wrap": true,
                "size": "sm"
              }
            ]
          }
        ]
      },
      "footer": {
        "type": "box",
        "layout": "vertical",
        "spacing": "sm",
        "contents": [
          {
            "type": "button",
            "action": {
              "type": "message",
              "label": "興味がある",
              "text": "座禅に行きたいです。"
            }
          },
          {
            "type": "button",
            "action": {
              "type": "message",
              "label": "興味がない",
              "text": "座禅には興味がありません。"
            }
          },
          {
            "type": "spacer",
            "size": "sm"
          }
        ],
        "flex": 0
      }
    }
    return message_panel
  end
  
  def sample_plan2
    message_panel = {
      "type": "bubble",
      "hero": {
        "type": "image",
        "url": "https://line-boot-sign-post-yu23ki14.c9users.io/assets/ichigo-43d4a4a5bd486fbfea7cdb3e111480a7d991d38c5124bfd57befcbffb4fdac0a.jpg",
        "size": "full",
        "aspectRatio": "20:13",
        "aspectMode": "cover",
        "action": {
          "type": "uri",
          "uri": "http://www.oofuna-kannon.or.jp/"
        }
      },
      "body": {
        "type": "box",
        "layout": "vertical",
        "contents": [
          {
            "type": "text",
            "text": "鎌倉観光イチゴ農園 ",
            "weight": "bold",
            "size": "xl"
          },
          {
            "type": "box",
            "layout": "vertical",
            "margin": "lg",
            "spacing": "sm",
            "contents": [
              {
                "type": "text",
                "text": "おいしいイチゴが食べられます。",
                "wrap": true,
                "size": "sm"
              }
            ]
          }
        ]
      },
      "footer": {
        "type": "box",
        "layout": "vertical",
        "spacing": "sm",
        "contents": [
          {
            "type": "button",
            "action": {
              "type": "message",
              "label": "興味がある",
              "text": "いちご狩りに行きたいです。"
            }
          },
          {
            "type": "button",
            "action": {
              "type": "message",
              "label": "興味がない",
              "text": "いちご狩りには興味がありません。"
            }
          },
          {
            "type": "spacer",
            "size": "sm"
          }
        ],
        "flex": 0
      }
    }
    return message_panel
  end
  
  def plan_complete
      message_panel = {
        "type": "bubble",
        "body": {
          "type": "box",
          "layout": "vertical",
          "contents": [
            {
              "type": "text",
              "text": "プラン作成を完了して、確認しますか？",
              "weight": "bold",
              "size": "lg",
              "wrap": true
            }
          ]
        },
        "footer": {
          "type": "box",
          "layout": "vertical",
          "spacing": "sm",
          "contents": [
            {
              "type": "box",
              "layout": "vertical",
              "spacing": "sm",
              "contents": [
                {
                  "type": "button",
                  "action": {
                    "type":"message",
                    "label":"はい",
                    "text":"プラン作成完了！"
                  }
                },
                {
                  "type": "button",
                  "action": {
                    "type":"message",
                    "label":"もう少しリコメンドをもらう",
                    "text":"もう少しリコメンドしてほしい"
                  }
                }
              ]
            }
          ],
          "flex": 0
        }
      }
    return message_panel
  end
  
  def plan_show
   message_panel = {
    "type": "bubble",
    "body": {
      "type": "box",
      "layout": "vertical",
      "contents": [
        {
          "type": "text",
          "text": "このプランで保存しますか？",
          "weight": "bold",
          "size": "lg"
        },
        {
          "type": "box",
          "layout": "vertical",
          "margin": "lg",
          "spacing": "sm",
          "contents": [
            {
              "type": "box",
              "layout": "baseline",
              "spacing": "sm",
              "contents": [
                {
                  "type": "text",
                  "text": "7:45",
                  "color": "#aaaaaa",
                  "size": "sm",
                  "flex": 1
                },
                {
                  "type": "text",
                  "text": "出発",
                  "wrap": true,
                  "color": "#666666",
                  "size": "sm",
                  "flex": 5
                }
              ]
            },
            {
              "type": "box",
              "layout": "baseline",
              "spacing": "sm",
              "contents": [
                {
                  "type": "text",
                  "text": "8:00",
                  "color": "#aaaaaa",
                  "size": "sm",
                  "flex": 1
                },
                {
                  "type": "text",
                  "text": "新宿駅出発",
                  "wrap": true,
                  "color": "#666666",
                  "size": "sm",
                  "flex": 5
                }
              ]
            },
            {
              "type": "box",
              "layout": "baseline",
              "spacing": "sm",
              "contents": [
                {
                  "type": "text",
                  "text": "8:48",
                  "color": "#aaaaaa",
                  "size": "sm",
                  "flex": 1
                },
                {
                  "type": "text",
                  "text": "大船着",
                  "wrap": true,
                  "color": "#666666",
                  "size": "sm",
                  "flex": 5
                }
              ]
            },
            {
              "type": "box",
              "layout": "baseline",
              "spacing": "sm",
              "contents": [
                {
                  "type": "text",
                  "text": "8:53",
                  "color": "#aaaaaa",
                  "size": "sm",
                  "flex": 1
                },
                {
                  "type": "text",
                  "text": "大船観音寺着",
                  "wrap": true,
                  "color": "#666666",
                  "size": "sm",
                  "flex": 5
                }
              ]
            },
            {
              "type": "box",
              "layout": "baseline",
              "spacing": "sm",
              "contents": [
                {
                  "type": "text",
                  "text": "9:00",
                  "color": "#aaaaaa",
                  "size": "sm",
                  "flex": 1
                },
                {
                  "type": "text",
                  "text": "座禅開始",
                  "wrap": true,
                  "color": "#666666",
                  "size": "sm",
                  "flex": 5
                }
              ]
            },
            {
              "type": "box",
              "layout": "baseline",
              "spacing": "sm",
              "contents": [
                {
                  "type": "text",
                  "text": "10:00",
                  "color": "#aaaaaa",
                  "size": "sm",
                  "flex": 1
                },
                {
                  "type": "text",
                  "text": "座禅終了",
                  "wrap": true,
                  "color": "#666666",
                  "size": "sm",
                  "flex": 5
                }
              ]
            },
            {
              "type": "box",
              "layout": "baseline",
              "spacing": "sm",
              "contents": [
                {
                  "type": "text",
                  "text": "10:15",
                  "color": "#aaaaaa",
                  "size": "sm",
                  "flex": 1
                },
                {
                  "type": "text",
                  "text": "大船駅出発",
                  "wrap": true,
                  "color": "#666666",
                  "size": "sm",
                  "flex": 5
                }
              ]
            },
            {
              "type": "box",
              "layout": "baseline",
              "spacing": "sm",
              "contents": [
                {
                  "type": "text",
                  "text": "10:20",
                  "color": "#aaaaaa",
                  "size": "sm",
                  "flex": 1
                },
                {
                  "type": "text",
                  "text": "湘南深沢駅着",
                  "wrap": true,
                  "color": "#666666",
                  "size": "sm",
                  "flex": 5
                }
              ]
            },
            {
              "type": "box",
              "layout": "baseline",
              "spacing": "sm",
              "contents": [
                {
                  "type": "text",
                  "text": "10:40",
                  "color": "#aaaaaa",
                  "size": "sm",
                  "flex": 1
                },
                {
                  "type": "text",
                  "text": "鎌倉観光いちご農園到着",
                  "wrap": true,
                  "color": "#666666",
                  "size": "sm",
                  "flex": 5
                }
              ]
            },
            {
              "type": "box",
              "layout": "baseline",
              "spacing": "sm",
              "contents": [
                {
                  "type": "text",
                  "text": "11:15",
                  "color": "#aaaaaa",
                  "size": "sm",
                  "flex": 1
                },
                {
                  "type": "text",
                  "text": "いちご狩り終わり",
                  "wrap": true,
                  "color": "#666666",
                  "size": "sm",
                  "flex": 5
                }
              ]
            },
            {
              "type": "box",
              "layout": "baseline",
              "spacing": "sm",
              "contents": [
                {
                  "type": "text",
                  "text": "11:35",
                  "color": "#aaaaaa",
                  "size": "sm",
                  "flex": 1
                },
                {
                  "type": "text",
                  "text": "湘南深沢駅着",
                  "wrap": true,
                  "color": "#666666",
                  "size": "sm",
                  "flex": 5
                }
              ]
            }
          ]
        }
      ]
    },
    "footer": {
      "type": "box",
      "layout": "vertical",
      "spacing": "sm",
      "contents": [
        {
          "type": "button",
          "action": {
            "type": "message",
            "label":"OK",
            "text":"これで保存！"
          }
        },
        {
          "type": "spacer",
          "size": "sm"
        }
      ],
      "flex": 0
      }
    }
    return message_panel
  end
  
  def arrive
    
  end
  
  private
    def arrive_params
      
      params.require(:arrive).permit(:line_user_id, :arrive)
    end
  
end
