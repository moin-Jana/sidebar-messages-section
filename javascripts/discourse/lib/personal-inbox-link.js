import BaseCustomSidebarSectionLink from "discourse/lib/sidebar/base-custom-sidebar-section-link";
import { i18n } from "discourse-i18n";

export default class PersonalInboxLink extends BaseCustomSidebarSectionLink {
  name = "personal-inbox";
  text = i18n(themePrefix("personal_inbox.text"));
  title = i18n(themePrefix("personal_inbox.title"));
  route = "userPrivateMessages.user";
  prefixType = "icon";
  prefixValue = "inbox";

  constructor(currentUser, pmState) {
    super();
    this.currentUser = currentUser;
    this.pmState = pmState;
  }

  get models() {
    return [this.currentUser];
  }

  get unreadCount() {
    const pmState = this.pmState;
    if (!pmState?.states) {
      return (this._cachedCount = 0);
    }

    const count =
      pmState.lookupCount("unread", { inboxFilter: "user" }) +
      pmState.lookupCount("new", { inboxFilter: "user" });
    return count;
  }

  get showDot() {
    return !this.currentUser.sidebarShowCountOfNewItems && this.unreadCount > 0;
  }

  get classNames() {
    if (this.showDot || this.unreadCount === 0) {
      return "";
    }
    if (this.unreadCount >= 100) {
      return "pm-inbox-count pm-inbox-count-99plus";
    }
    return `pm-inbox-count pm-inbox-count-${this.unreadCount}`;
  }

  get suffixType() {
    return this.showDot ? "icon" : "";
  }

  get suffixValue() {
    return this.showDot ? "circle" : "";
  }

  get suffixCSSClass() {
    return this.showDot ? "urgent" : "";
  }
}
