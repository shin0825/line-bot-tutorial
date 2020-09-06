class LinebotController < ApplicationController
  require 'line/bot'

  protect_from_forgery :except => [:callback]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
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
          # LINEから送られてきたメッセージが「アンケート」と一致するかチェック
          if event.message['text'].eql?('アンケート')
            # private内のtemplateメソッドを呼び出します。
            client.reply_message(event['replyToken'], template)
          end
        when Line::Bot::Event::MessageType::Follow #友達登録イベント
          userId = event['source']['userId']
          User.find_or_create_by(uid: userId)
        when Line::Bot::Event::MessageType::Unfollow　#友達削除イベント
          userId = event['source']['userId']
          user = User.find_by(uid: userId)
          user.destroy if user.present?
        end
      end
    }

    head :ok
  end

  private

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
