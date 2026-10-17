include $(TOPDIR)/rules.mk

PKG_VERSION:=0.1

include $(INCLUDE_DIR)/package.mk

define Package/doornet2-base
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=DoorNet2-V0.1 policy and upgrade preservation
  DEPENDS:=+uci
endef

define Package/doornet2-base/description
  Idempotent DoorNet2 defaults, upgrade preservation, and the independent
  WeChatDirect domain set. This package does not start proxy or DNS services.
endef

define Package/doornet2-base/conffiles
/etc/config/doornet2
/etc/doornet2/wechatdirect.domains
endef

define Build/Compile
endef

define Package/doornet2-base/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/doornet2 $(1)/etc/config/doornet2
	$(INSTALL_DIR) $(1)/etc/doornet2
	$(INSTALL_DATA) ./files/etc/doornet2/wechatdirect.domains $(1)/etc/doornet2/wechatdirect.domains
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/etc/uci-defaults/99-doornet2-base $(1)/etc/uci-defaults/99-doornet2-base
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/doornet2-policy $(1)/etc/init.d/doornet2-policy
	$(INSTALL_DIR) $(1)/usr/libexec
	$(INSTALL_BIN) ./files/usr/libexec/doornet2-policy $(1)/usr/libexec/doornet2-policy
	$(INSTALL_DIR) $(1)/lib/upgrade/keep.d
	$(INSTALL_DATA) ./files/lib/upgrade/keep.d/50-doornet2 $(1)/lib/upgrade/keep.d/50-doornet2
endef

$(eval $(call BuildPackage,doornet2-base))
