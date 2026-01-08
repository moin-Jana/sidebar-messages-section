import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";
import GroupInboxLink from "../lib/group-inbox-link";
import PersonalInboxLink from "../lib/personal-inbox-link";

export default apiInitializer((api) => {
  const currentUser = api.getCurrentUser();
  if (!currentUser) {
    return;
  }

  const router = api.container.lookup("service:router");
  const pmState = api.container.lookup("service:pm-topic-tracking-state");

  const showPersonalInbox = (() => {
    const mode = settings.show_personal_inbox;
    if (mode === "All users") {
      return true;
    }
    if (mode === "Nobody") {
      return false;
    }
    return currentUser.can_send_private_messages;
  })();

  const advancedGroupConfig = (
    settings.advanced_group_inbox_configuration || []
  )
    .map((entry, index) => ({
      index,
      groupId: entry?.group?.length ? Number(entry.group[0]) : null,
      customName: entry?.custom_name?.trim() || null,
    }))
    .filter((entry) => entry.groupId);

  const hiddenGroupIds = (settings.hide_group_inboxes || "")
    .split("|")
    .map(Number)
    .filter(Boolean);

  const groupsWithMessages = currentUser.groupsWithMessages || [];
  const groupsById = new Map(groupsWithMessages.map((g) => [g.id, g]));

  if (currentUser.admin) {
    warnAboutHiddenAdvancedGroups(
      api,
      advancedGroupConfig,
      hiddenGroupIds,
      groupsById
    );
  }

  const orderedGroups = buildOrderedGroups(
    advancedGroupConfig,
    groupsById,
    groupsWithMessages,
    hiddenGroupIds
  );

  const sidebarLinks = buildSidebarLinks(
    currentUser,
    pmState,
    showPersonalInbox,
    orderedGroups
  );

  if (!sidebarLinks.length) {
    return;
  }

  api.addSidebarSection((BaseCustomSidebarSection) => {
    return class InboxSection extends BaseCustomSidebarSection {
      name = "inbox-section";
      text = i18n(themePrefix("messages.title"));
      actionsIcon = "plus";

      get actions() {
        return [
          {
            id: "newPersonalMessage",
            title: i18n(themePrefix("messages.action")),
            action: () => router.transitionTo("new-message"),
          },
        ];
      }

      get links() {
        return sidebarLinks;
      }
    };
  }, "main");
});

function warnAboutHiddenAdvancedGroups(
  api,
  advancedGroupConfig,
  hiddenGroupIds,
  groupsById
) {
  const conflictedConfigs = advancedGroupConfig.filter((config) =>
    hiddenGroupIds.includes(config.groupId)
  );

  if (!conflictedConfigs.length) {
    return;
  }

  const names = conflictedConfigs.map((config) => {
    const group = groupsById.get(config.groupId);

    if (config.customName) {
      return config.customName;
    }

    if (group?.name) {
      return group.name;
    }

    return "group " + ` ${config.index + 1}`;
  });

  api.addGlobalNotice(
    i18n(themePrefix("warnings.hidden_advanced_groups"), {
      groups: names.join(", "),
    }),
    "group-inbox-hidden-advanced-conflict",
    {
      level: "warn",
      dismissable: true,
      dismissDuration: moment.duration(1, "week"),
    }
  );
}

function buildOrderedGroups(
  advancedGroupConfig,
  groupsById,
  groupsWithMessages,
  hiddenGroupIds
) {
  const orderedGroups = [];

  for (const config of advancedGroupConfig) {
    const group = groupsById.get(config.groupId);

    if (!group) {
      continue;
    }

    if (hiddenGroupIds.includes(group.id)) {
      continue;
    }

    orderedGroups.push({
      group,
      customName: config.customName,
    });
  }

  const advancedIds = new Set(advancedGroupConfig.map((c) => c.groupId));

  for (const group of groupsWithMessages) {
    if (hiddenGroupIds.includes(group.id)) {
      continue;
    }

    if (advancedIds.has(group.id)) {
      continue;
    }

    orderedGroups.push({
      group,
      customName: null,
    });
  }

  return orderedGroups;
}

function buildSidebarLinks(
  currentUser,
  pmState,
  showPersonalInbox,
  orderedGroups
) {
  const links = [];

  if (showPersonalInbox) {
    links.push(new PersonalInboxLink(currentUser, pmState));
  }

  for (const { group, customName } of orderedGroups) {
    links.push(new GroupInboxLink(currentUser, pmState, group, customName));
  }

  return links;
}
