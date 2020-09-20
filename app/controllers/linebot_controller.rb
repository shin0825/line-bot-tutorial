class LinebotController < ApplicationController
  require 'line/bot'

  THUMBNAIL_URL = 'https://via.placeholder.com/1024x1024'
  HORIZONTAL_THUMBNAIL_URL = 'https://via.placeholder.com/1024x768'
  QUICK_REPLY_ICON_URL = 'https://via.placeholder.com/64x64'

  @hoge = false

  protect_from_forgery :except => [:callback]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    sample = ['食費','雑費','交遊費']
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head :bad_request
    end

    events = client.parse_events_from(body)

    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          puts '@hoge'
          puts @hoge ? 'a!' : 'e?'
          # LINEから送られてきたメッセージが「アンケート」と一致するかチェック
          if sample.include?(event.message['text'])
            @hoge = true
            reply_content(event, {
              type: 'text',
              text: '[QUICK REPLY]',
              quickReply: {
                items: [
                  {
                    type: "action",
                    imageUrl: QUICK_REPLY_ICON_URL,
                    action: {
                      type: "message",
                      label: "Sushi",
                      text: "Sushi"
                    }
                  },
                  {
                    type: "action",
                    action: {
                      type: "location",
                      label: "Send location"
                    }
                  },
                  {
                    type: "action",
                    imageUrl: QUICK_REPLY_ICON_URL,
                    action: {
                      type: "camera",
                      label: "Open camera",
                    }
                  },
                  {
                    type: "action",
                    imageUrl: QUICK_REPLY_ICON_URL,
                    action: {
                      type: "cameraRoll",
                      label: "Open cameraRoll",
                    }
                  },
                  {
                    type: "action",
                    action: {
                      type: "postback",
                      label: "buy",
                      data: "action=buy&itemid=111",
                      text: "buy",
                    }
                  },
                  {
                    type: "action",
                    action: {
                      type: "message",
                      label: "Yes",
                      text: "Yes"
                    }
                  },
                  {
                    type: "action",
                    action: {
                      type: "datetimepicker",
                      label: "Select date",
                      data: "storeId=12345",
                      mode: "datetime",
                      initial: "2017-12-25t00:00",
                      max: "2018-01-24t23:59",
                      min: "2017-12-25t00:00"
                    }
                  },
                ],
              },
            })
          elsif event.message['text'].eql?('アンケート')
            # private内のtemplateメソッドを呼び出します。
            client.reply_message(event['replyToken'], template)
          elsif @hoge
              puts 'にゃんぽこ'
              client.reply_message(event['replyToken'], template)
              @hoge = false
            els
          end
        end
      when Line::Bot::Event::Follow #友達登録イベント
        puts 'フォローきちゃ'
        userId = event['source']['userId']
        User.find_or_create_by(uid: userId)
      when Line::Bot::Event::Unfollow #友達削除イベント
        puts 'まぢやみ'
        userId = event['source']['userId']
        user = User.find_by(uid: userId)
        user.destroy if user.present?
      end
    }

    head :ok
  end

  def reply_text(event, texts)
    texts = [texts] if texts.is_a?(String)
    client.reply_message(
      event['replyToken'],
      texts.map { |text| {type: 'text', text: text} }
    )
  end

  def reply_content(event, messages)
    res = client.reply_message(
      event['replyToken'],
      messages
    )
    puts res.read_body if res.code != 200
  end

  private
  def action

  end

  def template
    {
      "type": "template",
      "altText": "非対応のデバイス。",
      "template": {
          "type": "confirm",
          "text": "確認させてください。",
          "actions": [
              {
                "type": "message",
                # Botから送られてきたメッセージに表示される文字列です。
                "label": "いいよ。",
                # ボタンを押した時にBotに送られる文字列です。
                "text": "いいよ。"
              },
              {
                "type": "message",
                "label": "ダメだね。",
                "text": "ダメよ。"
              }
          ]
      }
    }
  end
end
