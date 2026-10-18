include $(TOPDIR)/rules.mk

PKG_NAME:=doornet2-base
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-only

include $(INCLUDE_DIR)/package.mk

define Package/doornet2-base
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=DoorNet2-V0.1 defaults and configuration-preservation policy
  DEPENDS:=+uci +dnsmasq-full
endef

define Package/doornet2-base/description
Non-disruptive DoorNet2 defaults. User-configured services and network
configuration remain under UCI control.
endef

define Build/Compile
endef

define Package/doornet2-base/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults $(1)/etc/doornet2
	$(INSTALL_BIN) ./files/90-doornet2-policy $(1)/etc/uci-defaults/90-doornet2-policy
	$(INSTALL_DATA) ./files/wechatdirect.domains $(1)/etc/doornet2/wechatdirect.domains
endef

$(eval $(call BuildPackage,doornet2-base))
