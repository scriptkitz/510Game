--
-- Author: zhong
-- Date: 2016-06-28 16:40:04
--
--庄家申请列表
local module_pre = "game.yule.sicbobattle.src"

local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")
local g_var = ExternalFun.req_var;
local UserItem = module_pre .. ".views.layer.userlist.UserItem"

local ApplyListLayer = class("ApplyListLayer", function (  )
	local colorLayer = cc.LayerColor:create(cc.c4b(0,0,0,100))
	return colorLayer
end) --
ApplyListLayer.BT_CLOSE = 1
ApplyListLayer.BT_APPLY = 2

function ApplyListLayer:ctor( viewParent)
	--注册事件
	local function onLayoutEvent( event )
		if event == "exit" then
			self:onExit()
        elseif event == "enterTransitionFinish" then
        	self:onEnterTransitionFinish()
        end
	end
	self:registerScriptHandler(onLayoutEvent)

	--
	self.m_parent = viewParent

	--用户列表
	self.m_userlist = {}

	--加载csb资源
	local csbNode = ExternalFun.loadCSB("game/118_applyList.csb", self)
	csbNode:setPosition(yl.WIDTH/2,yl.HEIGHT/2)
	local sp_bg = csbNode:getChildByName("118_applyBg")
	self.m_spBg = sp_bg
	local content = sp_bg:getChildByName("content")

	--用户列表
	local m_tableView = cc.TableView:create(content:getContentSize())
	m_tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
	m_tableView:setPosition(content:getPositionX(),content:getPositionY())
	m_tableView:setDelegate()
	m_tableView:registerScriptHandler(self.cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)
	m_tableView:registerScriptHandler(handler(self, self.tableCellAtIndex), cc.TABLECELL_SIZE_AT_INDEX)
	m_tableView:registerScriptHandler(handler(self, self.numberOfCellsInTableView), cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
	sp_bg:addChild(m_tableView)
	self.m_tableView = m_tableView;
	content:removeFromParent()

	--关闭按钮
	local function btnEvent( sender, eventType )
		if eventType == ccui.TouchEventType.ended then
			self:onButtonClickedEvent(sender:getTag(), sender);
		end
	end
	local btn = sp_bg:getChildByName("Button_close")
	btn:setTag(ApplyListLayer.BT_CLOSE)
	btn:addTouchEventListener(btnEvent);

	local function applyBtn( sender, eventType )
		if eventType == ccui.TouchEventType.ended then
			self:onApplyClickedEvent(sender:getTag(), sender);
		end
	end
	--申请按钮
	btn = sp_bg:getChildByName("Button_shangzhuang")
	btn:addTouchEventListener(applyBtn);
	self.m_btnApply = btn

	--申请按钮时间间隔
	self.b_isApplytouch = true

	--content:removeFromParent()
end


function ApplyListLayer:refreshScore( score )
	local condition = self.m_spBg:getChildByName("Text_1")
	print("刷新金币"  .. score)

	score = self:toApplyScore(score)
	condition:setString(string.format( "上庄条件:" .. score .. "金币" ))
end

function ApplyListLayer:toApplyScore( score )

	score=score or -1  --IORI--
	local scorestr = ExternalFun.formatScore(score)
	if score < 10000 then
		return scorestr
	end

	if score < 100000000 then
		scorestr = string.format("%d万", score / 10000)
		return scorestr
	end
	scorestr = string.format("%d亿", score / 100000000)
	return scorestr
end

function ApplyListLayer:refreshList( userlist )
	self:setVisible(true)
	self.m_userlist = userlist
	self.m_tableView:reloadData()
	print("@@@@上庄列表@@@@@")
	print(#userlist)
	--dump(userlist)
	if nil == self.m_parent or nil == self.m_parent.getApplyState then
		ExternalFun.enableBtn(self.m_btnApply, false)
		return
	end

	--获取当前申请状态
	local state = self.m_parent:getApplyState()	
	local str1 = nil
	local str2 = nil
	local str3 = nil
	ExternalFun.enableBtn(self.m_btnApply, false)
	--未申请状态则申请、申请状态则取消申请、已申请则取消申请
	if state == self.m_parent._apply_state.kCancelState then
		str1 = "118_btn_apply_1.png"
		str2 = "118_btn_apply_2.png"
		str3 = "118_btn_apply_3.png"
		--申请条件限制
		ExternalFun.enableBtn(self.m_btnApply, self.m_parent:getApplyable())
	elseif state == self.m_parent._apply_state.kApplyState then
		str1 = "118_btn_cancelSQ_1.png"
		str2 = "118_btn_cancelSQ_2.png"
		str3 = "118_btn_cancelSQ_3.png"
		ExternalFun.enableBtn(self.m_btnApply, true)
	elseif state == self.m_parent._apply_state.kApplyedState then
		str1 = "118_btn_cancelSZ_1.png"
		str2 = "118_btn_cancelSZ_2.png"
		str3 = "118_btn_cancelSZ_3.png"
		--取消上庄限制
		ExternalFun.enableBtn(self.m_btnApply, self.m_parent:getCancelable())
	end

	print("state . " .. state)
	local btn = self.m_btnApply
	if nil ~= str1 and nil ~= str2 and nil ~= str3 then
		btn:loadTextureNormal(str1,UI_TEX_TYPE_PLIST)
		btn:loadTexturePressed(str2,UI_TEX_TYPE_PLIST)
		btn:loadTextureDisabled(str3,UI_TEX_TYPE_PLIST)
	end
	btn:setTag(state)
end
--刷新上庄按钮状态
function ApplyListLayer:refreshBtnState(  )
	if nil == self.m_parent or nil == self.m_parent.getApplyState then
		ExternalFun.enableBtn(self.m_btnApply, false)
		return
	end

	--获取当前申请状态
	local state = self.m_parent:getApplyState()
	print(" lien 130刷新上庄按钮状态")
	print("state",state)
	print("self.m_parent._apply_state.kApplyedState",self.m_parent._apply_state.kApplyedState)
	if state == self.m_parent._apply_state.kApplyedState then
		--已申请状态，下庄限制
		ExternalFun.enableBtn(self.m_btnApply, self.m_parent:getCancelable())
	end
end

--tableview
function ApplyListLayer.cellSizeForTable( view, idx )
	return g_var(UserItem).getSize()
end

function ApplyListLayer:numberOfCellsInTableView( view )
	if nil == self.m_userlist then
		return 0
	else
		return #self.m_userlist
	end
end

function ApplyListLayer:tableCellAtIndex( view, idx )
	local cell = view:dequeueCell()
	
	if nil == self.m_userlist then
		return cell
	end

	local useritem = self.m_userlist[idx+1].m_userItem
	local var_bRob = self.m_userlist[idx+1].m_bRob
	local item = nil

	if nil == cell then
		cell = cc.TableViewCell:new()
		item = g_var(UserItem):create()
		item:setPosition(view:getViewSize().width * 0.5, 10)
		item:setName("user_item_view")
		cell:addChild(item)
	else
		item = cell:getChildByName("user_item_view")
	end

	if nil ~= useritem and nil ~= item then
		item:refresh(useritem,var_bRob, idx / #self.m_userlist)
	end

	return cell
end
--

function ApplyListLayer:onButtonClickedEvent( tag, sender )
	ExternalFun.playClickEffect()
	if ApplyListLayer.BT_CLOSE == tag then
		self:setVisible(false)
	end
end

function ApplyListLayer:onApplyClickedEvent( tag,sender )
	ExternalFun.playClickEffect()
	--需要整个消息流程完毕才能执行下一次点击,防止快速点击和卡点点击
	if not self.b_isApplytouch then
		return
	end
	if nil ~= self.m_parent then
		self.b_isApplytouch = false
		self.m_parent:applyBanker(tag)
	end
end

function ApplyListLayer:onExit()
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.listener)
end

function ApplyListLayer:onEnterTransitionFinish()
	self:registerTouch()
end

function ApplyListLayer:registerTouch()
	local function onTouchBegan( touch, event )
		return self:isVisible()
	end

	local function onTouchEnded( touch, event )
		local pos = touch:getLocation();
		local m_spBg = self.m_spBg
        pos = m_spBg:convertToNodeSpace(pos)
        local rec = cc.rect(0, 0, m_spBg:getContentSize().width, m_spBg:getContentSize().height)
        if false == cc.rectContainsPoint(rec, pos) then
            self:setVisible(false)
        end        
	end

	local listener = cc.EventListenerTouchOneByOne:create();
	listener:setSwallowTouches(true)
	self.listener = listener;
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN );
    listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED );
    local eventDispatcher = self:getEventDispatcher();
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self);
end
return ApplyListLayer