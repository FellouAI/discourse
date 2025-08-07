import Component from "@glimmer/component";
import { concat } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { next } from "@ember/runloop";
import { service } from "@ember/service";
import { htmlSafe, isHTMLSafe } from "@ember/template";
import { modifier } from "ember-modifier";
import { and, eq } from "truth-helpers";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import PluginOutlet from "discourse/components/plugin-outlet";
import PostCountOrBadges from "discourse/components/topic-list/post-count-or-badges";
import TopicExcerpt from "discourse/components/topic-list/topic-excerpt";
import TopicLink from "discourse/components/topic-list/topic-link";
import TopicStatus from "discourse/components/topic-status";
import UserLink from "discourse/components/user-link";
import avatar from "discourse/helpers/avatar";
import categoryLink from "discourse/helpers/category-link";
import concatClass from "discourse/helpers/concat-class";
import discourseTags from "discourse/helpers/discourse-tags";
import formatDate from "discourse/helpers/format-date";
import lazyHash from "discourse/helpers/lazy-hash";
import topicFeaturedLink from "discourse/helpers/topic-featured-link";
import { wantsNewWindow } from "discourse/lib/intercept-click";
import {
  applyBehaviorTransformer,
  applyValueTransformer,
} from "discourse/lib/transformer";
import DiscourseURL from "discourse/lib/url";
import { i18n } from "discourse-i18n";

export default class Item extends Component {
  @service historyStore;
  @service site;
  @service siteSettings;

  highlightIfNeeded = modifier((element) => {
    if (this.args.topic.id === this.historyStore.get("lastTopicIdViewed")) {
      element.dataset.isLastViewedTopic = true;

      this.highlightRow(element);
      next(() => this.historyStore.delete("lastTopicIdViewed"));

      if (this.shouldFocusLastVisited) {
        // Using next() so it always runs after clean-dom
        next(() => element.querySelector(".main-link .title")?.focus());
      }
    } else if (this.args.topic.get("highlight")) {
      // highlight new topics that have been loaded from the server or the one we just created
      this.highlightRow(element);
      next(() => this.args.topic.set("highlight", false));
    }
  });

  get isSelected() {
    return this.args.selected?.includes(this.args.topic);
  }

  get tagClassNames() {
    return this.args.topic.tags?.map((tagName) => `tag-${tagName}`);
  }

  get expandPinned() {
    let expandPinned;
    if (
      !this.args.topic.pinned ||
      (this.useMobileLayout && !this.siteSettings.show_pinned_excerpt_mobile) ||
      (this.site.desktopView && !this.siteSettings.show_pinned_excerpt_desktop)
    ) {
      expandPinned = false;
    } else {
      expandPinned =
        (this.args.expandGloballyPinned && this.args.topic.pinned_globally) ||
        this.args.expandAllPinned;
    }

    return applyValueTransformer(
      "topic-list-item-expand-pinned",
      expandPinned,
      { topic: this.args.topic, mobileView: this.useMobileLayout }
    );
  }

  get shouldFocusLastVisited() {
    return this.site.desktopView && this.args.focusLastVisitedTopic;
  }

  @action
  navigateToTopic(topic, href) {
    this.historyStore.set("lastTopicIdViewed", topic.id);
    DiscourseURL.routeTo(href || topic.url);
  }

  highlightRow(element) {
    element.dataset.testWasHighlighted = true;

    // Remove any existing highlighted class
    element.addEventListener(
      "animationend",
      () => element.classList.remove("highlighted"),
      { once: true }
    );

    element.classList.add("highlighted");
  }

  @action
  onTitleFocus(event) {
    event.target.closest(".topic-list-item").classList.add("selected");
  }

  @action
  onTitleBlur(event) {
    event.target.closest(".topic-list-item").classList.remove("selected");
  }

  @action
  onBulkSelectToggle(e) {
    if (e.target.checked) {
      this.args.selected.addObject(this.args.topic);

      if (this.args.bulkSelectHelper.lastCheckedElementId && e.shiftKey) {
        const bulkSelects = [...document.querySelectorAll("input.bulk-select")];
        const from = bulkSelects.indexOf(e.target);
        const to = bulkSelects.findIndex(
          (el) => el.id === this.args.bulkSelectHelper.lastCheckedElementId
        );
        const start = Math.min(from, to);
        const end = Math.max(from, to);

        bulkSelects
          .slice(start, end)
          .filter((el) => !el.checked)
          .forEach((checkbox) => checkbox.click());
      }

      this.args.bulkSelectHelper.lastCheckedElementId = e.target.id;
    } else {
      this.args.selected.removeObject(this.args.topic);
      this.args.bulkSelectHelper.lastCheckedElementId = null;
    }
  }

  @action
  click(e) {
    applyBehaviorTransformer(
      "topic-list-item-click",
      () => {
        if (
          e.target.classList.contains("raw-topic-link") ||
          e.target.classList.contains("post-activity") ||
          e.target.classList.contains("badge-posts")
        ) {
          if (wantsNewWindow(e)) {
            return;
          }

          e.preventDefault();
          this.navigateToTopic(this.args.topic, e.target.href);
          return;
        }

        // make full row click target on mobile, due to size constraints
        if (
          this.site.mobileView &&
          e.target.matches(
            ".topic-list-data, .main-link, .right, .topic-item-stats, .topic-item-stats__category-tags, .discourse-tags"
          )
        ) {
          if (wantsNewWindow(e)) {
            return;
          }

          e.preventDefault();
          this.navigateToTopic(this.args.topic, this.args.topic.lastUnreadUrl);
          return;
        }
      },
      {
        topic: this.args.topic,
        event: e,
        navigateToTopic: this.navigateToTopic,
      }
    );
  }

  @action
  keyDown(e) {
    if (
      e.key === "Enter" &&
      (e.target.classList.contains("post-activity") ||
        e.target.classList.contains("badge-posts"))
    ) {
      e.preventDefault();
      this.navigateToTopic(this.args.topic, e.target.href);
    }
  }



  get useMobileLayout() {
    return applyValueTransformer(
      "topic-list-item-mobile-layout",
      this.site.mobileView,
      { topic: this.args.topic }
    );
  }

  get additionalClasses() {
    return applyValueTransformer("topic-list-item-class", [], {
      topic: this.args.topic,
      index: this.args.index,
    });
  }

  get style() {
    const parts = applyValueTransformer("topic-list-item-style", [], {
      topic: this.args.topic,
      index: this.args.index,
    });

    const safeParts = parts.filter(Boolean).filter((part) => {
      if (isHTMLSafe(part)) {
        return true;
      }
      // eslint-disable-next-line no-console
      console.error(
        "topic-list-item-style must be formed of htmlSafe strings. Skipped unsafe value:",
        part
      );
    });

    if (safeParts.length) {
      return htmlSafe(safeParts.join("\n"));
    }
  }

   @action
  setIframeWidthForTopic(iframe) {
    // eslint-disable-next-line no-console
    console.log("setIframeWidthForTopic called with iframe:", iframe);

    if (!iframe) {
      // eslint-disable-next-line no-console
      console.log("setIframeWidthForTopic: iframe not found");
      return;
    }

    // 获取父容器（topic-card-image-placeholder）的宽度
    const container = iframe.closest('.topic-card-image-placeholder');
    if (!container) {
      // eslint-disable-next-line no-console
      console.log("setIframeWidthForTopic: container not found");
      return;
    }

    // eslint-disable-next-line no-console
    const containerWidth = container.offsetWidth;
    // eslint-disable-next-line no-console
    console.log("setIframeWidthForTopic: container width:", containerWidth);

    // iframe 原始尺寸（屏幕尺寸）
    const iframeOriginalWidth = document.documentElement.clientWidth;
    const iframeOriginalHeight = document.documentElement.clientHeight;

    // 目标尺寸（容器尺寸）
    const targetWidth = containerWidth;
    const targetHeight = 136;

    // 计算宽度和高度的缩放比例
    const scaleRatioX = targetWidth / iframeOriginalWidth;
    const scaleRatioY = targetHeight / iframeOriginalHeight;

    // 使用较小的缩放比例，确保 iframe 完全适应容器
    const finalScaleRatio = Math.max(scaleRatioX, scaleRatioY);

    // 设置 iframe 样式
    iframe.style.width = `${iframeOriginalWidth}px`;
    iframe.style.height = `${iframeOriginalHeight}px`;
    iframe.style.transform = `scale(${finalScaleRatio})`;
    iframe.style.transformOrigin = "top left";
    iframe.style.display = "block";
    iframe.style.border = "none";
    iframe.style.position = "absolute";
    iframe.style.top = "0";
    iframe.style.left = "0";
    iframe.style.pointerEvents = "none";
  }



  <template>
    <div
      {{! template-lint-disable no-invalid-interactive }}
      {{this.highlightIfNeeded}}
      {{on "keydown" this.keyDown}}
      {{on "click" this.click}}
      data-topic-id={{@topic.id}}
      role={{this.role}}
      aria-level={{this.ariaLevel}}
      class={{concatClass
        "topic-list-item"
        (if @topic.category (concat "category-" @topic.category.fullSlug))
        (if (eq @topic @lastVisitedTopic) "last-visit")
        (if @topic.visited "visited")
        (if @topic.hasExcerpt "has-excerpt")
        (if (and this.expandPinned @topic.hasExcerpt) "excerpt-expanded")
        (if @topic.unseen "unseen-topic")
        (if @topic.unread_posts "unread-posts")
        (if @topic.liked "liked")
        (if @topic.archived "archived")
        (if @topic.bookmarked "bookmarked")
        (if @topic.pinned "pinned")
        (if @topic.closed "closed")
        this.tagClassNames
        this.additionalClasses
      }}
      style={{this.style}}
    >
      <PluginOutlet
        @name="above-topic-list-item"
        @outletArgs={{lazyHash topic=@topic}}
      />
      {{! Do not include @columns as argument to the wrapper outlet below ~}}
      {{! We don't want it to be able to override core behavior just copy/pasting the code ~}}
      <PluginOutlet
        @name="topic-list-item"
        @outletArgs={{lazyHash
          topic=@topic
          bulkSelectEnabled=@bulkSelectEnabled
          onBulkSelectToggle=this.onBulkSelectToggle
          isSelected=this.isSelected
          hideCategory=@hideCategory
          tagsForUser=@tagsForUser
          showTopicPostBadges=@showTopicPostBadges
          navigateToTopic=this.navigateToTopic
        }}
      >
        <div class="topic-card-content">
          {{#if @bulkSelectEnabled}}
            <div class="topic-card-bulk-select">
              <label for="bulk-select-{{@topic.id}}">
                <input
                  {{on "click" this.onBulkSelectToggle}}
                  checked={{this.isSelected}}
                  type="checkbox"
                  id="bulk-select-{{@topic.id}}"
                  class="bulk-select"
                />
              </label>
            </div>
          {{/if}}

          <div class="topic-card-image">
            {{#if @topic.image_url}}
              <img src={{@topic.image_url}} alt="Topic image" />
            {{else}}
              <div class="topic-card-image-placeholder">
                <iframe
                  src="http://localhost:4200/latest"
                  frameborder="0"
                  title="Youware"
                  scrolling="no"
                  {{didInsert this.setIframeWidthForTopic}}
                ></iframe>
              </div>
            {{/if}}
          </div>

          <div class="topic-card-body">
            <div class="topic-card-title">
              <TopicLink
                {{on "focus" this.onTitleFocus}}
                {{on "blur" this.onTitleBlur}}
                @topic={{@topic}}
                class="raw-link raw-topic-link"
              />
              <PluginOutlet
                @name="topic-list-after-title"
                @outletArgs={{lazyHash topic=@topic}}
              />
            </div>

            <div class="topic-card-description">
              {{#if @topic.excerpt}}
                {{@topic.excerpt}}
              {{else}}
                {{@topic.fancy_title}}
              {{/if}}
            </div>

            <div class="topic-card-footer">
              <div class="topic-card-user">
                <UserLink @username={{@topic.lastPosterUser.username}}>
                  {{avatar @topic.lastPosterUser imageSize="small"}}
                </UserLink>
                <span class="topic-card-username">{{@topic.lastPosterUser.username}}</span>
              </div>

              <div class="topic-card-stats">
                <span class="topic-stat">
                  <span class="d-icon d-icon-eye"></span>
                  <span class="stat-number">{{@topic.views}}</span>
                </span>
                <span class="topic-stat">
                  <span class="d-icon d-icon-thumbtack"></span>
                  <span class="stat-number">{{@topic.like_count}}</span>
                </span>
                <span class="topic-stat">
                  <span class="d-icon d-icon-reply"></span>
                  <span class="stat-number">{{@topic.reply_count}}</span>
                </span>
              </div>
            </div>
          </div>
        </div>
      </PluginOutlet>
    </div>
  </template>
}
